#!/usr/bin/env bash
set -euo pipefail

# Pushes the 'conjur' image to various Docker registries
# There are essentially three flows this script supports
# - Pushing images to the internal registry during the early pipeline stage
# - Pushing an "edge"-tagged image to DockerHub
# - Publishing images to public registries on new project releases during a
#   tag-triggered build
#
# The default flow when no parameters are supplied is to publish images to
# public registries. This does require that the TAG_NAME variable is set, which
# happens automatically in tag-triggered builds.
#
# To publish to a (private) internal registry, run the script with the
# "--registry-prefix=*" flag to supply the registry prefix.
#
# To publish an "edge"-tagged release to DockerHub, run the script with the
# "--edge" flag.

# shellcheck disable=SC1091
. build_utils.sh

function print_help() {
  echo "Usage: $0 [OPTION...]"
  echo " --registry-prefix=STRING; optional registry prefix to prepend to '/cyberark/conjur'"
  echo " --edge; optional flag to publish edge-tagged image to DockerHub"
}

REGISTRY_PREFIX=""
PUBLISH_EDGE=false
TAG="$(version_tag)"
LOCAL_IMAGE="conjur:${TAG}"
RH_LOCAL_IMAGE="conjur-ubi:${TAG}"
IMAGE_NAME="cyberark/conjur"
REDHAT_IMAGE="scan.connect.redhat.com/ospid-9fb7aea1-0c01-4527-8def-242f3cde7dc6/conjur"

for arg in "$@"; do
  case $arg in
    --edge )
      PUBLISH_EDGE=true
      shift
      ;;
    --registry-prefix=* )
      REGISTRY_PREFIX="${arg#*=}"
      shift
      ;;
    --registry-prefix )
      echo "This script expects the flag value to be provided as --registry-prefix=STRING"
      print_help
      exit 1
      ;;
    * )
      echo "Unknown option: ${arg}"
      print_help
      exit 1
      ;;
    esac
done

if [[ "${PUBLISH_EDGE}" = true ]]; then

  if [[ ! -z "${REGISTRY_PREFIX}" ]]; then
    REGISTRY_PREFIX="${REGISTRY_PREFIX}/"
  fi

  # This script is running to publish the edge tagged image to DockerHub
  tag_and_push "edge" "${LOCAL_IMAGE}" "${REGISTRY_PREFIX}${IMAGE_NAME}"

  # Push the edge build into the internal registry
  tag_and_push "edge" "${LOCAL_IMAGE}" "registry.tld/conjur"

  # Push the UBI edge build into the internal registry
  tag_and_push "edge" "conjur-ubi:${TAG}" "registry.tld/conjur-ubi"

elif [[ ! -z "${REGISTRY_PREFIX}" ]]; then

  # This is not running on a tag-triggered build, and a registry prefix has
  # been supplied. Publish to the specified registry.

  # Push the VERSION-SHA tagged images to our internal registry
  v="$(< VERSION)"
  tag_and_push "${v}-${TAG}" "${LOCAL_IMAGE}" "${REGISTRY_PREFIX}/conjur"
  tag_and_push "${v}-${TAG}" "conjur-test:${TAG}" "${REGISTRY_PREFIX}/conjur-test"
  tag_and_push "${v}-${TAG}" "conjur-ubi:${TAG}" "${REGISTRY_PREFIX}/conjur-ubi"

  # Push SHA only tagged images to our internal registry
  tag_and_push "${TAG}" "${LOCAL_IMAGE}" "${REGISTRY_PREFIX}/conjur"
  tag_and_push "${TAG}" "conjur-test:${TAG}" "${REGISTRY_PREFIX}/conjur-test"
  tag_and_push "${TAG}" "conjur-ubi:${TAG}" "${REGISTRY_PREFIX}/conjur-ubi"

elif [[ ! -z "${TAG_NAME:-}" ]]; then

  # This is running on a tag-triggered build, and public images should be published
  TAG="${TAG_NAME//"v"}"

  # Push latest, 1.x.y, 1.x, and 1 to DockerHub and internal registry
  readarray -t prefix_versions < <(gen_versions "${TAG}")
  for v in latest "${TAG}" "${prefix_versions[@]}"; do
    # Push to Dockerhub
    tag_and_push "${v}" "${LOCAL_IMAGE}" "${IMAGE_NAME}"
    # Push to Internal Registry - this is so the current release tags
    # are also present in the internal registry.
    tag_and_push "${v}" "${LOCAL_IMAGE}" "registry.tld/conjur"
    tag_and_push "${v}" "conjur-ubi:${TAG}" "registry.tld/conjur-ubi"
  done

  # Publish only the tag version to the Redhat container registry
  if docker login scan.connect.redhat.com -u unused -p "${REDHAT_API_KEY}"; then
    tag_and_push "${TAG}" "${RH_LOCAL_IMAGE}" "${REDHAT_IMAGE}"
  else
    echo 'Failed to log in to scan.connect.redhat.com'
    exit 1
  fi

else

  echo "This script is not running in a tag-triggered build."
  echo "Please supply either:"
  echo " - The registry prefix with the --registry-prefix flag, or"
  echo " - The --edge flag to publish an edge release to DockerHub."
  exit 1
fi
