#!/bin/bash -ex

mkdir -p tmp

version=$(cat ../VERSION)-g$(git rev-parse --short HEAD)

cp ../conjur-possum_"$version"_amd64.deb tmp/conjur-possum.deb

docker build -t possum-base -f Dockerfile.base .

docker build -t possum --no-cache .
