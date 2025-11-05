#!/usr/bin/env bash
set -euo pipefail

. build_utils.sh

# Publishes the 'conjur' image to docker registries
# There are 3 primary flows:
# - Publish build-specific (commit SHA) based images internally
# - Publish edge and release builds images internally and to DockerHub
# - Promote an existing image to a customer release and publish to latest
#
# If no parameters are specified, no images are pushed
function print_help() {
  echo "Usage: $0 [OPTION...] <version>"
  echo " --internal: publish SHA tagged images internally"
  echo " --edge: publish images as edge versions to registry.tld and dockerhub"
  echo " --promote: publish images as a promotion (latest and less specific versions) to registry.tld and dockerhub"
  echo " --version=VERSION: specify version number to use"
  echo " --base-version=VERSION: specify base image version number to use to apply tags to"
  echo " --arch=ARCH: specify architecture for tagging an image (default 'amd64'). Possible values are: amd64,arm64"
}

PUBLISH_EDGE=false
PUBLISH_RELEASE=false
PUBLISH_INTERNAL=false
PROMOTE=false
DOCKERHUB=false
VERSION=$(<VERSION)
ARCH="amd64"

LOCAL_TAG="$(version_tag)"

for arg in "$@"; do
  case $arg in
    --internal )
      PUBLISH_INTERNAL=true
      shift
      ;;
    --edge )
      PUBLISH_EDGE=true
      shift
      ;;
    --release )
      PUBLISH_RELEASE=true
      shift
      ;;
    --promote )
      PROMOTE=true
      shift
      ;;
    --dockerhub )
      DOCKERHUB=true
      shift
      ;;
    --version=* )
      VERSION="${arg#*=}"
      shift
      ;;
    --base-version=* )
      LOCAL_TAG="${arg#*=}"
      shift
      ;;
    --arch=* )
      ARCH="${arg#*=}"
      shift
      ;;
    * )
      echo "Unknown option: ${arg}"
      print_help
      exit 1
      ;;
    esac
done

LOCAL_IMAGE="conjur:${LOCAL_TAG}"
RH_LOCAL_IMAGE="conjur-ubi:${LOCAL_TAG}"
IMAGE_NAME="cyberark/conjur"

# Normalize version number in the case of '+' included
VERSION="$(echo -n "${VERSION}" | tr "+" "_")"

# Don't publish to DockerHub unless the build is in the main conjur repo
if [[ "${JOB_NAME}" != cyberark--conjur/* ]];
then
  DOCKERHUB=false
fi

# Only push SHA images on internal
if [[ "${PUBLISH_INTERNAL}" = true ]]; then
  echo "Pushing ${LOCAL_TAG}-${ARCH} tagged images to registry.tld..."
  # Always push SHA versioned images internally
  tag_and_push "${VERSION}-${LOCAL_TAG}-${ARCH}" "${LOCAL_IMAGE}" "registry.tld/conjur"
  tag_and_push "${VERSION}-${LOCAL_TAG}-${ARCH}" "conjur-test:${LOCAL_TAG}" "registry.tld/conjur-test"
  tag_and_push "${VERSION}-${LOCAL_TAG}-${ARCH}" "conjur-ubi:${LOCAL_TAG}" "registry.tld/conjur-ubi"

  # Push SHA only tagged images to our internal registry
  tag_and_push "${LOCAL_TAG}-${ARCH}" "${LOCAL_IMAGE}" "registry.tld/conjur"
  tag_and_push "${LOCAL_TAG}-${ARCH}" "conjur-test:${LOCAL_TAG}" "registry.tld/conjur-test"
  tag_and_push "${LOCAL_TAG}-${ARCH}" "conjur-ubi:${LOCAL_TAG}" "registry.tld/conjur-ubi"
fi

if [[ "${PUBLISH_EDGE}" = true ]]; then
  echo "Pushing edge versions..."

  # Push image to internal registry
  tag_and_push "edge-${ARCH}" "${LOCAL_IMAGE}" "registry.tld/${IMAGE_NAME}"
  tag_and_push "edge-${ARCH}" "${RH_LOCAL_IMAGE}" "registry.tld/conjur-ubi"

  # Publish release specific and edge tags to dockerhub
  if [[ "${DOCKERHUB}" = true ]]; then
    echo "Pushing to DockerHub"

    tag_and_push "edge" "${LOCAL_IMAGE}" "${IMAGE_NAME}"
  fi
fi

if [[ "${PUBLISH_RELEASE}" = true ]]; then
  echo "Pushing release versions..."

  # Publish release specific versions internally
  echo "Pushing ${VERSION}-${ARCH} to registry.tld..."
  tag_and_push "${VERSION}-${ARCH}" "${LOCAL_IMAGE}" "registry.tld/${IMAGE_NAME}"
  tag_and_push "${VERSION}-${ARCH}" "${RH_LOCAL_IMAGE}" "registry.tld/conjur-ubi"

  # Publish release specific and edge tags to dockerhub
  if [[ "${DOCKERHUB}" = true ]]; then
    echo "Pushing to DockerHub"
    
    tag_and_push "${VERSION}" "${LOCAL_IMAGE}" "${IMAGE_NAME}"
  fi
fi

if [[ "${PROMOTE}" = true ]]; then
  echo "Promoting image to ${VERSION}-${ARCH}"
  
  # Push edge, latest, 1.x.y, 1.x, and 1 images
  readarray -t prefix_versions < <(gen_versions "${VERSION}")

  for version in edge latest "${prefix_versions[@]}"; do
    echo "Pushing images for tag: $version-${ARCH}"

    tag_and_push "${version}-${ARCH}" "registry.tld/${IMAGE_NAME}:${LOCAL_TAG}-${ARCH}" "registry.tld/${IMAGE_NAME}"
    tag_and_push "${version}-${ARCH}" "registry.tld/conjur-ubi:${LOCAL_TAG}-${ARCH}" "registry.tld/conjur-ubi"

    if [[ "${DOCKERHUB}" ]]; then
      echo "Pushing to DockerHub"
      
      tag_and_push "${version}-${ARCH}" "${LOCAL_IMAGE}-${ARCH}" "${IMAGE_NAME}"
    fi
  done
fi
