#!/bin/bash -ex

tag=registry.tld/possum:${BRANCH_NAME}_$(< VERSION)
docker tag possum ${tag}
docker push ${tag}
