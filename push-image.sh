#!/bin/bash -ex

tag=registry.tld/possum:$(< VERSION)-$(git rev-parse --short HEAD)
docker tag possum ${tag}
docker push ${tag}
