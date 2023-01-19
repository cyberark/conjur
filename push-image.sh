#!/bin/bash -e

# Push the 'conjur' image to various Docker registries
# Push tagged images on master branch
# Release images can be created by passing the desired tag to this script
# Ex: ./push-image 4.9.5.1

# shellcheck disable=SC1091
. version_utils.sh

TAG="${1:-$(version_tag)}"
VERSION="$(< VERSION)"
SOURCE_IMAGE="conjur:$TAG"

CONJUR_REGISTRY=registry.tld
IMAGE_NAME=cyberark/conjur

# both old-style 'conjur' and new-style 'cyberark/conjur'
INTERNAL_IMAGES=`echo $CONJUR_REGISTRY/{conjur,$IMAGE_NAME}`

function main() {
  echo "TAG = $TAG"
  echo "VERSION = $VERSION"

  # always push VERSION-SHA tags to our registry
  tag_and_push $TAG $INTERNAL_IMAGES

  git fetch --tags || : # Jenkins brokenness workaround
  local git_description=`git describe`

  # if on a tag matching the VERSION, assume tests have passed and push to latest and stable tags
  # and push releases to DockerHub
  if [[ $git_description = v$VERSION ]]; then
    tag_and_push latest $INTERNAL_IMAGES

    # only do 1-stable and 1.2-stable for 1.2.3-dev
    # (1.2.3-stable doesn't make sense if there is a released version called 1.2.3)
    for v in `gen_versions $VERSION`; do
      tag_and_push $v-stable $INTERNAL_IMAGES
    done

    echo "Revision $git_description matches version exactly, pushing releases..."
    for v in latest $VERSION `gen_versions $VERSION`; do
      tag_and_push $v $IMAGE_NAME
    done
  else
    echo "Revision $git_description does not match version $VERSION exactly, not releasing."
  fi
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
