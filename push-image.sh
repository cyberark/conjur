#!/bin/bash -e

# Push the 'conjur' image to various Docker registries
# Push stable images on master branch
# Release images can be created by passing the desired tag to this script
# Ex: ./push-image 4.9.5.1

TAG="${1:-$(< VERSION)-$(git rev-parse --short HEAD)}"

SOURCE_IMAGE='conjur'
INTERNAL_IMAGE='registry.tld/conjur'
DOCKERHUB_IMAGE='cyberark/conjur'
QUAY_IMAGE='quay.io/cyberark/conjur'

function main() {
  echo "TAG = $TAG"

  tag_and_push $INTERNAL_IMAGE $TAG

  if [ "$BRANCH_NAME" = "master" ]; then
    local stable_tag="$(< VERSION)-stable"

    echo "TAG = $stable_tag, stable image"

    tag_and_push $INTERNAL_IMAGE $stable_tag

    tag_and_push $DOCKERHUB_IMAGE $TAG
    tag_and_push $DOCKERHUB_IMAGE $stable_tag

    tag_and_push $QUAY_IMAGE $TAG
    tag_and_push $QUAY_IMAGE $stable_tag
  fi
}

function tag_and_push() {
  local image="$1"
  local tag="$2"

  docker tag "$SOURCE_IMAGE" "$image:$tag"
  docker push "$image:$tag"
}

main
