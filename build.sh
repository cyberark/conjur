#!/bin/bash -ex

TAG="$(< VERSION)-$(git rev-parse --short HEAD)"
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

echo "Building conjur Docker image"
docker build -t conjur .

echo "Tagging conjur:$TAG"
docker tag conjur "conjur:$TAG"

echo "Building test container"
docker build -t conjur-test -f Dockerfile.test .

if [[ $RUN_DEV = true ]]; then
  echo "Building dev container"
  docker build -t conjur-dev -f Dockerfile.dev .
fi
