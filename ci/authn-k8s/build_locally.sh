#!/bin/bash

sni_cert=$1

# Set up VERSION file for local development
if [ ! -f "../../VERSION" ]; then
  echo -n "0.0.dev" > ../../VERSION
fi

if [[ ! -z "$sni_cert" ]]; then
  sni_cert="$(realpath $1)"
fi

function copy_cert() {
  image=$1
  sni_cert=$2

  if [[ ! -z $sni_cert ]]; then
    docker rm temp_container || true
    docker create --name temp_container "$image"
    docker cp "$sni_cert" "temp_container:/opt/conjur/etc/ssl/ca/${sni_cert##*/}"
    docker commit temp_container "$image"
    docker rm temp_container
  fi
}

cd "$(git rev-parse --show-toplevel)" || exit

TAG="$(git rev-parse --short=8 HEAD)"
export TAG="$TAG"
docker build --no-cache -t "conjur:$TAG" .
copy_cert "conjur:$TAG" "$sni_cert"
docker build --no-cache -t "registry.tld/conjur:$TAG" .
copy_cert "registry.tld/conjur:$TAG" "$sni_cert"
docker build --no-cache --build-arg "VERSION=$TAG" -t "registry.tld/conjur-test:$TAG" -f Dockerfile.test .
