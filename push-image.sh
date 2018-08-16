#!/bin/bash -e

# Push the 'conjur' image to various Docker registries
# Push stable images on master branch
# Release images can be created by passing the desired tag to this script
# Ex: ./push-image 4.9.5.1

# shellcheck disable=SC1091
. version_utils.sh

TAGS="${1:-$(version_tags)}"
IFS=',' read -ra TAGS_ARR <<< "$TAGS"

INTERNAL_IMAGE='registry.tld/conjur'
INTERNAL_IMAGE_NEW='registry.tld/cyberark/conjur'  # We'll transition to this
DOCKERHUB_IMAGE='cyberark/conjur'
QUAY_IMAGE='quay.io/cyberark/conjur'

function main() {
  for tag in "${TAGS_ARR[@]}"; do
    echo "TAG = $tag"

    tag_and_push $INTERNAL_IMAGE $tag
    tag_and_push $INTERNAL_IMAGE_NEW $tag

    if [ "$BRANCH_NAME" = "master" ]; then
      local latest_tag='latest'
      local stable_tag="$(< VERSION)-stable"

      echo "tag = $stable_tag, stable image"

      tag_and_push $INTERNAL_IMAGE $latest_tag
      tag_and_push $INTERNAL_IMAGE $stable_tag

      tag_and_push $INTERNAL_IMAGE_NEW $latest_tag
      tag_and_push $INTERNAL_IMAGE_NEW $stable_tag

      tag_and_push $DOCKERHUB_IMAGE $tag
      tag_and_push $DOCKERHUB_IMAGE $latest_tag
      tag_and_push $DOCKERHUB_IMAGE $stable_tag

      tag_and_push $QUAY_IMAGE $tag
      tag_and_push $QUAY_IMAGE $latest_tag
      tag_and_push $QUAY_IMAGE $stable_tag
    fi
  done
}

function tag_and_push() {
  local image="$1"
  local tag="$2"

  docker tag "conjur:$tag" "$image:$tag"
  docker push "$image:$tag"
}

main
