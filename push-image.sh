#!/bin/bash -e

# Push the 'conjur' image to various Docker registries
# Push stable images on master branch
# Release images can be created by passing the desired tag to this script
# Ex: ./push-image 4.9.5.1

TAG="${1:-$(< VERSION)-$(git rev-parse --short HEAD)}"
DESTINATION="${2:-'internal'}"  # internal or external, defaults to internal

SOURCE_IMAGE="conjur:$TAG"
INTERNAL_IMAGE='registry.tld/conjur'
LATEST_TAG='latest'
STABLE_TAG="$(< VERSION)-stable"

DOCKERHUB_IMAGE='cyberark/conjur'
QUAY_IMAGE='quay.io/cyberark/conjur'

function main() {
  echo "TAG = $TAG"
  tag_and_push $INTERNAL_IMAGE $TAG

  if [ "$BRANCH_NAME" = "master" ]; then
    push_stable_to_internal_registries
    if [ "$DESTINATION" = 'external' ]; then
      push_stable_to_external_registries
    fi
  fi
}

function push_stable_to_internal_registries() {
  echo "STABLE_TAG = $STABLE_TAG, internal"

  tag_and_push $INTERNAL_IMAGE $LATEST_TAG
  tag_and_push $INTERNAL_IMAGE $STABLE_TAG
}

function push_stable_to_external_registries() {
  echo "STABLE_TAG = $STABLE_TAG, external"

  echo "Pushing to DockerHub"
  tag_and_push $DOCKERHUB_IMAGE $TAG
  tag_and_push $DOCKERHUB_IMAGE $LATEST_TAG
  tag_and_push $DOCKERHUB_IMAGE $STABLE_TAG

  echo "Pushing to Quay"
  tag_and_push $QUAY_IMAGE $TAG
  tag_and_push $QUAY_IMAGE $LATEST_TAG
  tag_and_push $QUAY_IMAGE $STABLE_TAG
}

function tag_and_push() {
  local image="$1"
  local tag="$2"

  docker tag $SOURCE_IMAGE "$image:$tag"
  docker push "$image:$tag"
}

main
