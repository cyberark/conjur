#!/bin/bash -ex

tag=registry.tld/possum:${BRANCH_NAME//\//_}_$(< VERSION)
docker tag possum ${tag}
docker push ${tag}
