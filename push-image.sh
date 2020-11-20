#!/usr/bin/env bash
set -e

# Push the 'conjur' image to various Docker registries
# Push tagged images on master branch
# Release images can be created by passing the desired tag to this script
# Ex: ./push-image 4.9.5.1

# shellcheck disable=SC1091
. version_utils.sh

TAG="$(version_tag)"
VERSION="$(< VERSION)"
SOURCE_IMAGE="conjur:$TAG"
RH_SOURCE_IMAGE="conjur-ubi:$TAG"

CONJUR_REGISTRY="registry.tld"
IMAGE_NAME="cyberark/conjur"
REDHAT_IMAGE="scan.connect.redhat.com/ospid-9fb7aea1-0c01-4527-8def-242f3cde7dc6/conjur"

# both old-style 'conjur' and new-style 'cyberark/conjur'
INTERNAL_IMAGES=("$CONJUR_REGISTRY/conjur" "$CONJUR_REGISTRY/$IMAGE_NAME")

function main() {
  local push_location=$1

  if [[ "$push_location" = "internal" ]]; then
    publish_internal_images
  elif [[ "$push_location" = "external" ]]; then 
    publish_external_images
  else
    echo "You must run push-images.sh with an argument of either 'external' or"
    echo "'internal' to specify the destination for the published images."
    exit 1 
  fi
}

function publish_internal_images() {
  # always push VERSION-SHA tags to our registry
  tag_and_push "$TAG" "$SOURCE_IMAGE" "${INTERNAL_IMAGES[@]}"

  # We only publish images with version strings when produced from a tag build
  # in Jenkins
  if [ -n "$TAG_NAME" ]; then
    # Our git tags may include metadata (e.g. `+dap.`). When this is the case
    # we replace the `+` with `_` to produce a valid docker tag
    TAG_NAME="$(tr "+" "_" <<<"$TAG_NAME")"

    # For tags we push a `latest` docker images, as well as progressively
    # specific versions.
    tag_and_push latest "$SOURCE_IMAGE" "${INTERNAL_IMAGES[@]}"
    tag_and_push "$TAG_NAME" "$SOURCE_IMAGE" "${INTERNAL_IMAGES[@]}"

    # Only do 1-stable and 1.2-stable for 1.2.3-dev.  1.2.3-stable doesn't make
    # sense if there is a released version called 1.2.3
    local prefix_versions
    readarray -t prefix_versions < <(gen_versions "$TAG_NAME")
    for v in "${prefix_versions[@]}"; do
      tag_and_push "$v-stable" "$SOURCE_IMAGE" "${INTERNAL_IMAGES[@]}"
    done
  fi
}

function publish_external_images() {
  if [[ -z "${TAG_NAME:-}" ]]; then
    echo "Please supply environment variable TAG_NAME."
    echo "If you see this error in Jenkins it means the publish script was run"
    echo "for a build that wasn't triggered by a tag -" \
      "please check publish stage conditions."
    exit 1
  fi

  # Publish the public `cyberark/conjur` image to DockerHub
  local prefix_versions
  readarray -t prefix_versions < <(gen_versions "$TAG_NAME")
  for v in latest "$TAG_NAME" "${prefix_versions[@]}"; do
    tag_and_push "$v" "$SOURCE_IMAGE" "$IMAGE_NAME"
  done

  # Publish only the tag version to the Redhat Registries
  # Note: We want $REDHAT_API_KEY to expand inside bash -c, not here.
  # shellcheck disable=SC2016
  if summon bash -c \
    'docker login scan.connect.redhat.com -u unused -p "$REDHAT_API_KEY"';
  then
    tag_and_push "$VERSION" "$RH_SOURCE_IMAGE" "$REDHAT_IMAGE"
  else
    echo 'Failed to log in to scan.connect.redhat.com'
    exit 1
  fi
}

# tag_and_publish tag source image1 image2 ...
function tag_and_push() {
  local tag="$1"; shift
  local source="$1"; shift

  for image in "$@"; do
    local target=$image:$tag
    echo "Tagging and pushing $target..."
    docker tag "$source" "$target"
    docker push "$target"
  done
}

main "$@"
