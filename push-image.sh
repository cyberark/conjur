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

CONJUR_REGISTRY=registry.tld
IMAGE_NAME=cyberark/conjur

# both old-style 'conjur' and new-style 'cyberark/conjur'
INTERNAL_IMAGES=`echo $CONJUR_REGISTRY/{conjur,$IMAGE_NAME}`

function main() {
  # always push VERSION-SHA tags to our registry
  tag_and_push $TAG $INTERNAL_IMAGES

  # this script is only auto-triggered on a tag, so it will always publish
  # releases to DockerHub
  tag_and_push latest $INTERNAL_IMAGES

  # only do 1-stable and 1.2-stable for 1.2.3-dev
  # (1.2.3-stable doesn't make sense if there is a released version called 1.2.3)
  for v in `gen_versions $TAG_NAME`; do
    tag_and_push $v-stable $INTERNAL_IMAGES
  done

  for v in latest $TAG_NAME `gen_versions $TAG_NAME`; do
    tag_and_push $v $IMAGE_NAME
  done
}

# tag_and_publish tag image1 image2 ...
function tag_and_push() {
  local tag="$1"
  shift

  for image in $*; do
    local target=$image:$tag
    echo Tagging and pushing $target...
    docker tag "$SOURCE_IMAGE" $target
    docker push $target
  done
}

main
