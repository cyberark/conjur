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

docker build -t conjur .
docker tag conjur "conjur:$TAG"

docker build -t conjur-test -f Dockerfile.test .

if [[ $RUN_DEV = true ]]; then
  docker build -t conjur-dev -f Dockerfile.dev .
fi
