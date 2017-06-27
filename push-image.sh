#!/bin/bash -ex

tag_with() {
  echo -n registry.tld/possum:$(< VERSION)-$1
}

branch_tag=$(tag_with $(git rev-parse --short HEAD))
docker tag possum $branch_tag
docker push $branch_tag

if [ "$BRANCH_NAME" = "master" ]; then
  stable_tag=$(tag_with stable)
  docker tag possum $stable_tag
  docker push $stable_tag
fi
  
