#!/bin/bash -ex

function main() {
  local version="$(< VERSION)-$(git rev-parse --short HEAD)"

  push_to_registries $version

  if [ "$BRANCH_NAME" = "master" ]; then
    local stable_version="$(< VERSION)-stable"
    push_to_registries $stable_version
  fi
}

function push_to_registries() {
  local version="$1"

  local internal_tag="registry.tld/possum:$version"
  docker tag possum $internal_tag
  docker push $internal_tag

  local dockerhub_tag="conjurinc/possum:$version"
  docker tag possum $dockerhub_tag
  docker push $dockerhub_tag

  local quay_tag="quay.io/conjur/possum:$version"
  docker tag possum $quay_tag
  docker push $quay_tag
}

main
