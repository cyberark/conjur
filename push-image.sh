#!/bin/bash -e

# Push the 'conjur' image to various Docker registries
# Push stable images on master branch
# Release images can be created by passing the desired tag to this script
# Ex: ./push-image external, ./push-image internal 4.9.5.1

DESTINATION="${1:-'internal'}"  # internal or external, defaults to internal
TAG="${2:-$(< VERSION)-$(git rev-parse --short HEAD)}"

SOURCE_IMAGE="conjur:$TAG"
INTERNAL_IMAGE="registry.tld/conjur:$TAG"

LATEST_TAG='latest'
STABLE_TAG="$(< VERSION)-stable"

DOCKERHUB_IMAGE='cyberark/conjur'
QUAY_IMAGE='quay.io/cyberark/conjur'

function main() {
  if [ "$DESTINATION" = "internal" ]; then
    echo "TAG = $TAG"
    docker tag $SOURCE_IMAGE $INTERNAL_IMAGE
    docker push $INTERNAL_IMAGE
  fi

  if [ "$BRANCH_NAME" = "master" ]; then
    push_stable_to_internal_registries

    if [ "$DESTINATION" = 'external' ]; then
      push_to_external_registries
    else
      echo "Skipping external push, DESTINATION '$DESTINATION' != 'internal'"
    fi

  else
    echo "Skipping stable push, BRANCH_NAME '$BRANCH_NAME' != 'master'"
  fi
}

function push_stable_to_internal_registries() {
  echo "STABLE_TAG = $STABLE_TAG, internal"

  tag_and_push $INTERNAL_IMAGE $LATEST_TAG
  tag_and_push $INTERNAL_IMAGE $STABLE_TAG
}

function push_to_external_registries() {
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

  docker pull $INTERNAL_IMAGE
  docker tag $INTERNAL_IMAGE "$image:$tag"
  docker push "$image:$tag"
}

main
