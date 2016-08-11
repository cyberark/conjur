#!/bin/bash -ex

./build.sh

docker tag -f possum registry.tld/conjurinc/possum:latest
docker tag -f possum registry.tld/conjurinc/possum:$(cat VERSION)

docker push registry.tld/conjurinc/possum:latest
docker push registry.tld/conjurinc/possum:$(cat VERSION)
