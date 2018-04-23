#!/bin/bash -ex

# shellcheck disable=SC1091
. version_utils.sh

TAG="$(version_tag)"
RUN_DEV=true

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -j|--jenkins)
    RUN_DEV=false
    ;;
    *)
    ;;
esac
shift # past argument or value
done

echo "Building image conjur:$TAG"
docker build -t "conjur:$TAG" .

echo "Building image conjur-test:$TAG container"
docker build --build-arg "VERSION=$TAG" -t "conjur-test:$TAG" -f Dockerfile.test .

if [[ $RUN_DEV = true ]]; then
  echo "Building image conjur-dev"
  docker build -t conjur-dev -f dev/Dockerfile.dev .
fi
