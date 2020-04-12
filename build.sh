#!/bin/bash -ex
#
# Builds Conjur Docker images
# Intended to be run from the project root dir
# usage: ./build.sh

# shellcheck disable=SC1091
. version_utils.sh

TAG="$(version_tag)"
RUN_DEV=true

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --jenkins)
    RUN_DEV=false
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
  local container=`docker create $image`
  docker export $container | docker import \
    --change "EXPOSE 80" \
    --change "ENV RAILS_ENV=production" \
    --change "WORKDIR /opt/conjur-server" \
    --change "ENV PATH /usr/local/rvm/rubies/ruby-2.5.7/bin:/usr/local/ssl/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    --change 'ENTRYPOINT ["conjurctl"]' \
    - $image
  docker rm $container
}

echo "Building image conjur:$TAG"
docker build -t "conjur:$TAG" .
flatten "conjur:$TAG"

echo "Building image conjur-test:$TAG container"
docker build --build-arg "VERSION=$TAG" -t "conjur-test:$TAG" -f Dockerfile.test .

if [[ $RUN_DEV = true ]]; then
  echo "Building image conjur-dev"
  docker build -t conjur-dev -f dev/Dockerfile.dev .
fi
