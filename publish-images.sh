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

PUBLISH_INTERNAL=false
VERSION=$(<VERSION)

LOCAL_TAG="$(version_tag)"

for arg in "$@"; do
  case $arg in
    --internal )
      PUBLISH_INTERNAL=true
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

# Normalize version number in the case of '+' included
VERSION="$(echo -n "${VERSION}" | tr "+" "_")"

# Only push SHA images on internal
if [[ "${PUBLISH_INTERNAL}" = true ]]; then
  echo "Pushing ${LOCAL_TAG} tagged images to registry.tld..."
  # Always push SHA versioned images internally
  tag_and_push "${VERSION}-${LOCAL_TAG}" "${LOCAL_IMAGE}" "registry.tld/conjur-cloud"
  tag_and_push "${VERSION}-${LOCAL_TAG}" "conjur-test:${LOCAL_TAG}" "registry.tld/conjur-test-cloud"
  tag_and_push "${VERSION}-${LOCAL_TAG}" "conjur-ubi:${LOCAL_TAG}" "registry.tld/conjur-ubi-cloud"

  # Push SHA only tagged images to our internal registry
  tag_and_push "${LOCAL_TAG}" "${LOCAL_IMAGE}" "registry.tld/conjur-cloud"
  tag_and_push "${LOCAL_TAG}" "conjur-test:${LOCAL_TAG}" "registry.tld/conjur-test-cloud"
  tag_and_push "${LOCAL_TAG}" "conjur-ubi:${LOCAL_TAG}" "registry.tld/conjur-ubi-cloud"
fi
