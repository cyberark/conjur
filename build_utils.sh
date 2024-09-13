#!/usr/bin/env bash

# Functions to generate version numbers for this project

function version_tag() {
  git rev-parse --short=8 HEAD
}

# generate set of less specific versions, eg. given 1.2.3 will print 1.2.3,
# 1.2 and 1
function gen_versions()
{
  local version=$1
  echo "$version"
  while [[ $version = *.* ]]; do
    version=${version%.*}
    echo "$version"
  done
}

# tag_and_publish tag source image1 image2 ...
function tag_and_push() {
  local tag="$1"; shift
  local source="$1"; shift

  for image in "$@"; do
    local target=$image:$tag
    echo "Tagging $source as $target and pushing..."
    docker tag "$source" "$target"
    docker push "$target"
  done
}

# prepare_manifest image tag
function prepare_manifest() {
  local image="$1"
  local tag="$2"

  docker pull "${image}:${tag}-amd64"
  docker pull "${image}:${tag}-arm64"

  docker manifest create \
    --insecure \
    "${image}:${tag}" \
    --amend "${image}:${tag}-amd64" \
    --amend "${image}:${tag}-arm64"

  docker manifest push --insecure "${image}:${tag}"

  # Because the bill of materials is created based on local docker images this is necessary in order to have
  # identical records in BOM files as previously, before multi-arch changes
  docker rmi "${image}:${tag}-amd64"
  docker rmi "${image}:${tag}-arm64"
  docker pull "${image}:${tag}"
}
