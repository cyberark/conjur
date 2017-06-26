#!/bin/bash -ex

tag=registry.tld/possum:${VERSION}-${BRANCH_NAME}
docker tag possum ${tag}
docker push ${tag}
