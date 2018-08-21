#!/bin/bash -e

# Push the 'conjur' image to various Docker registries
# Push stable images on master branch
# Release images can be created by passing the desired tag to this script
# Ex: ./push-image 4.9.5.1

# shellcheck disable=SC1091
. version_utils.sh

TAG="${1:-$(version_tag)}"
VERSION="$(< VERSION)"

SOURCE_IMAGE="conjur:$TAG"
INTERNAL_IMAGE='registry.tld/conjur'
INTERNAL_IMAGE_NEW='registry.tld/cyberark/conjur'  # We'll transition to this
DOCKERHUB_IMAGE='cyberark/conjur'
QUAY_IMAGE='quay.io/cyberark/conjur'

function main() {
  echo "TAG = $TAG"
  echo "VERSION = $VERSION"

  tag_and_push $INTERNAL_IMAGE $TAG
  tag_and_push $INTERNAL_IMAGE_NEW $TAG

  if [ "$BRANCH_NAME" = "master" ]; then
    local latest_tag='latest'
    local stable_tag="$(< VERSION)-stable"

    echo "TAG = $stable_tag, stable image"

    tag_and_push $INTERNAL_IMAGE $latest_tag
    tag_and_push $INTERNAL_IMAGE $stable_tag

    tag_and_push $INTERNAL_IMAGE_NEW $latest_tag
    tag_and_push $INTERNAL_IMAGE_NEW $stable_tag

    git fetch --tags
    tag_sha=`git rev-list -n 1 "v$VERSION"`
    head_sha=`git rev-list -n 1 HEAD`
    if [ "$tag_sha" = "$head_sha" ]; then
      # Add release tagged image to our internal repository
      tag_and_push $INTERNAL_IMAGE $VERSION
      tag_and_push $INTERNAL_IMAGE_NEW $VERSION

      # Add release tagged image to our DockerHub repository
      tag_and_push $DOCKERHUB_IMAGE $VERSION
      tag_and_push $DOCKERHUB_IMAGE $latest_tag

      # Add release tagged image to our Quay.io repository
      tag_and_push $QUAY_IMAGE $VERSION
      tag_and_push $QUAY_IMAGE $latest_tag
    fi
  fi
}

function tag_and_push() {
  local image="$1"
  local tag="$2"

  docker tag "$SOURCE_IMAGE" "$image:$tag"
  docker push "$image:$tag"
}

main
