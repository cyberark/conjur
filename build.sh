#!/bin/bash -ex
#
# Builds Conjur Docker images
# Intended to be run from the project root dir
# usage: ./build.sh

# shellcheck disable=SC1091
. version_utils.sh

TAG="$(version_tag)"
jenkins=false # Running on Jenkins (vs local dev machine)
REGISTRY_TEST_PATH="registry.tld/test"

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

# We want to build an image:
# 1. Always, when we're developing locally
# 2. Only if it doesn't already exist, when on Jenkins
image_needs_building() {
  [[ $jenkins = true ]] && 
    # doesn't already exist
    [[ "$(docker images -q "$1" 2> /dev/null)" == "" ]]
}

if image_needs_building "conjur:$TAG"; then
  echo "Building image conjur:$TAG"
  docker build -t "conjur:$TAG" .
  flatten "conjur:$TAG"
  docker tag "conjur:$TAG" "$REGISTRY_TEST_PATH/conjur:$TAG"

# Pushing conjur:$TAG and conjur-test:$TAG images to registry at this early stage (before tests)
# is done to allow image reuse on all agents instead of rebuilding them
# thus reducing time and using best practice of testing same artifact
# since conjur-test image is not flatten and based on conjur we are also reusing layers
# nevertheless, images has "test" prefix to allow future aggregated purging
  echo "Pushing image $REGISTRY_TEST_PATH/conjur:$TAG"
  docker push "$REGISTRY_TEST_PATH/conjur:$TAG"
fi

if image_needs_building "conjur-test:$TAG"; then
  echo "Building image conjur-test:$TAG container"
  docker build --build-arg "VERSION=$TAG" -t "conjur-test:$TAG" -f Dockerfile.test .
  docker tag "conjur-test:$TAG" "$REGISTRY_TEST_PATH/conjur-test:$TAG"

  echo "Pushing image $REGISTRY_TEST_PATH/conjur-test:$TAG"
  docker push "$REGISTRY_TEST_PATH/conjur-test:$TAG"
fi

if image_needs_building "conjur-ubi:$TAG"; then
  echo "Building image conjur-ubi:$TAG container"
  docker build --build-arg "VERSION=$TAG" -t "conjur-ubi:$TAG" -f Dockerfile.ubi .
  docker tag "conjur-ubi:$TAG" "$REGISTRY_TEST_PATH/conjur-ubi:$TAG"

  echo "Pushing image $REGISTRY_TEST_PATH/conjur-ubi:$TAG"
  docker push "$REGISTRY_TEST_PATH/conjur-ubi:$TAG"
fi

if [[ $jenkins = false ]]; then
  echo "Building image conjur-dev"
  docker build -t conjur-dev -f dev/Dockerfile.dev .
fi
