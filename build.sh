#!/usr/bin/env bash

set -ex

# Builds Conjur Docker images
# Intended to be run from the project root dir
# usage: ./build.sh

# shellcheck disable=SC1091
. build_utils.sh

TAG="$(version_tag)"
jenkins=false # Running on Jenkins (vs local dev machine)

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --jenkins)
    jenkins=true
    ;;
    *)
    ;;
esac
shift # past argument or value
done

# Flatten resulting image.
function flatten() {
  local image="$1"
  echo "Flattening image '$image'..."

  # Since `--squash` is still experimental, we have to flatten the image
  # by exporting and importing a container based on the source image. By
  # doing this though, we lose a lot of the Dockerfile variables that are
  # required for running the image (ENV, EXPOSE, WORKDIR, etc) so we
  # manually rebuild them.
  # See here for more details: https://github.com/moby/moby/issues/8334
  local container
  container=$(docker create "$image")
  docker export "$container" | docker import \
    --change "ENV PATH /usr/local/pgsql/bin:/var/lib/ruby/bin:/usr/local/ssl/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    --change "ENV LD_LIBRARY_PATH /usr/local/ssl/lib" \
    --change "ENV OPENSSL_FIPS 1" \
    --change "EXPOSE 80" \
    --change "ENV RAILS_ENV=production" \
    --change "WORKDIR /opt/conjur-server" \
    --change 'ENTRYPOINT ["conjurctl"]' \
    - "$image"
  docker rm "$container"
}

# Store the current git commit sha in a file so that it can be added to the container.
# This will enable users of the container to determine which revision of conjur
# the container was built from.
git rev-parse HEAD > conjur_git_commit

# We want to build an image:
# 1. Always, when we're developing locally
if [[ $jenkins = false ]]; then
  echo "Building image conjur-dev"
  docker build -t conjur-dev -f dev/Dockerfile.dev .
  exit 0
fi

# 2. Only if it doesn't already exist, when on Jenkins
image_doesnt_exist() {
  [[ "$(docker images -q "$1" 2> /dev/null)" == "" ]]
}

if image_doesnt_exist "conjur-cloud:$TAG"; then
  echo "Building image conjur-cloud:$TAG"
  docker build -t "conjur-cloud:$TAG" .
  flatten "conjur-cloud:$TAG"
fi

if image_doesnt_exist "conjur-test-cloud:$TAG"; then
  echo "Building image conjur-test-cloud:$TAG container"
  docker build --build-arg "VERSION=$TAG" -t "conjur-test-cloud:$TAG" -f Dockerfile.test .
fi

if image_doesnt_exist "conjur-ubi-cloud:$TAG"; then
  echo "Building image conjur-ubi-cloud:$TAG container"
  docker build --build-arg "VERSION=$TAG" -t "conjur-ubi-cloud:$TAG" -f Dockerfile.ubi .
fi
