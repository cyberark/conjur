#!/bin/bash -e

# Push the 'conjur' image to various Docker registries
# Push tagged images on master branch
# Release images can be created by passing the desired tag to this script
# Ex: ./push-image 4.9.5.1

# shellcheck disable=SC1091
. version_utils.sh

if [[ -z "${TAG_NAME:-}" ]]; then
  echo "Please supply environment variable TAG_NAME."
  echo "If you see this error in Jenkins it means the publish script was run"
  echo "for a build that wasn't triggered by a tag - please check publish stage conditions."
  exit 1
fi

TAG="${1:-$(version_tag)}"
VERSION="$(< VERSION)"
SOURCE_IMAGE="conjur:$TAG"
RH_SOURCE_IMAGE="conjur-ubi:$TAG"

CONJUR_REGISTRY="registry.tld"
IMAGE_NAME="cyberark/conjur"
REDHAT_IMAGE="scan.connect.redhat.com/ospid-9fb7aea1-0c01-4527-8def-242f3cde7dc6/conjur"

# both old-style 'conjur' and new-style 'cyberark/conjur'
INTERNAL_IMAGES=`echo $CONJUR_REGISTRY/{conjur,$IMAGE_NAME}`

function main() {
  # always push VERSION-SHA tags to our registry
  tag_and_push $TAG $SOURCE_IMAGE $INTERNAL_IMAGES

  # this script is only auto-triggered on a tag, so it will always publish
  # releases to DockerHub
  tag_and_push latest $SOURCE_IMAGE $INTERNAL_IMAGES

  # only do 1-stable and 1.2-stable for 1.2.3-dev
  # (1.2.3-stable doesn't make sense if there is a released version called 1.2.3)
  for v in `gen_versions $TAG_NAME`; do
    tag_and_push $v-stable $SOURCE_IMAGE $INTERNAL_IMAGES
  done

  for v in latest $TAG_NAME `gen_versions $TAG_NAME`; do
    tag_and_push $v $SOURCE_IMAGE $IMAGE_NAME
  done

  # Publish only the tag version to the Redhat Registries
  if summon bash -c 'docker login scan.connect.redhat.com -u unused -p "${REDHAT_API_KEY}"'; then
    tag_and_push $VERSION $RH_SOURCE_IMAGE $REDHAT_IMAGE
  else
    echo 'Failed to log in to scan.connect.redhat.com'
    exit 1
  fi
}

# tag_and_publish tag image1 image2 ...
function tag_and_push() {
  local tag="$1"
  local source="$2"
  shift

  for image in $*; do
    local target=$image:$tag
    echo Tagging and pushing $target...
    docker tag "$source" $target
    docker push $target
  done
}

main
