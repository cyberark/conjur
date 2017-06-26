#!/bin/bash -ex
env

tag=registry.tld/possum:${VERSION}-${BRANCH_NAME}
docker tag possum ${tag}
docker push ${tag}
