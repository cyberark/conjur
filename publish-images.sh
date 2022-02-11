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
  echo " --redhat: publish image to redhat registry"
  echo " --version=VERSION: specify version number to use"
  echo " --base-version=VERSION: specify base image version number to use to apply tags to"
}

PUBLISH_EDGE=false
PUBLISH_INTERNAL=false
PROMOTE=false
REDHAT=false
DOCKERHUB=false
VERSION=$(<VERSION)

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
    --promote )
      PROMOTE=true
      shift
      ;;
    --dockerhub )
      DOCKERHUB=true
      shift
      ;;
    --redhat )
      REDHAT=true
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
REDHAT_IMAGE="scan.connect.redhat.com/ospid-9fb7aea1-0c01-4527-8def-242f3cde7dc6/conjur"

# Normalize version number in the case of '+' included
VERSION="$(echo -n "${VERSION}" | tr "+" "_")"

# Don't publish to DockerHub unless the build is in the main conjur repo
if [[ "${JOB_NAME}" != cyberark--conjur/* ]];
then
  DOCKERHUB=false
fi

# Only push SHA images on internal
if [[ "${PUBLISH_INTERNAL}" = true ]]; then
  echo "Pushing ${LOCAL_TAG} tagged images to registry.tld..."
  # Always push SHA versioned images internally
  tag_and_push "${VERSION}-${LOCAL_TAG}" "${LOCAL_IMAGE}" "registry.tld/conjur"
  tag_and_push "${VERSION}-${LOCAL_TAG}" "conjur-test:${LOCAL_TAG}" "registry.tld/conjur-test"
  tag_and_push "${VERSION}-${LOCAL_TAG}" "conjur-ubi:${LOCAL_TAG}" "registry.tld/conjur-ubi"

  # Push SHA only tagged images to our internal registry
  tag_and_push "${LOCAL_TAG}" "${LOCAL_IMAGE}" "registry.tld/conjur"
  tag_and_push "${LOCAL_TAG}" "conjur-test:${LOCAL_TAG}" "registry.tld/conjur-test"
  tag_and_push "${LOCAL_TAG}" "conjur-ubi:${LOCAL_TAG}" "registry.tld/conjur-ubi"
fi

if [[ "${PUBLISH_EDGE}" = true ]]; then
  echo "Pushing edge versions..."

  # Publish release specific versions internally
  echo "Pushing ${VERSION} to registry.tld..."
  tag_and_push "${VERSION}" "${LOCAL_IMAGE}" "registry.tld/${IMAGE_NAME}"
  tag_and_push "${VERSION}" "${RH_LOCAL_IMAGE}" "registry.tld/conjur-ubi"

  # Push image to internal registry
  tag_and_push "edge" "${LOCAL_IMAGE}" "registry.tld/${IMAGE_NAME}"

  # Publish release specific and edge tags to dockerhub
  if [[ "${DOCKERHUB}" = true ]]; then
    tag_and_push "${VERSION}" "${LOCAL_IMAGE}" "${IMAGE_NAME}"
    tag_and_push "edge" "${LOCAL_IMAGE}" "${IMAGE_NAME}"
  fi
fi

if [[ "${PROMOTE}" = true ]]; then
  echo "Promoting image to ${VERSION}"

  # Push latest, 1.x.y, 1.x, and 1 images
  readarray -t prefix_versions < <(gen_versions "${VERSION}")

  for version in latest "${prefix_versions[@]}"; do
    tag_and_push "${version}" "${LOCAL_IMAGE}" "registry.tld/${IMAGE_NAME}"
    tag_and_push "${version}" "${RH_LOCAL_IMAGE}" "registry.tld/conjur-ubi"

    if [[ "${DOCKERHUB}" ]]; then
      tag_and_push "${version}" "${LOCAL_IMAGE}" "${IMAGE_NAME}"
    fi
  done
fi

if [[ "${REDHAT}" = true ]]; then
  echo "Publishing ${VERSION} to RedHat registry..."
  # Publish only the tag version to the Redhat container registry
  if docker login scan.connect.redhat.com -u unused -p "${REDHAT_API_KEY}"; then
    tag_and_push "${VERSION}" "${RH_LOCAL_IMAGE}" "${REDHAT_IMAGE}"
  else
    echo 'Failed to log in to scan.connect.redhat.com'
    exit 1
  fi
fi