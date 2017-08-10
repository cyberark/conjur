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

  local internal_tag="registry.tld/conjur:$version"
  docker tag conjur $internal_tag
  docker push $internal_tag
  
  local legacy_tag="registry.tld/possum:$version"
  docker tag conjur $legacy_tag
  docker push $legacy_tag

  local dockerhub_tag="conjurinc/conjur:$version"
  docker tag conjur $dockerhub_tag
  docker push $dockerhub_tag

  local quay_tag="quay.io/conjur/conjur:$version"
  docker tag conjur $quay_tag
  docker push $quay_tag
}

main
