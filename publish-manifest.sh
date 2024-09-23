#!/usr/bin/env bash
set -euo pipefail

. build_utils.sh

# Publishes the 'conjur' multi-architecture manifest to docker registries
# There are 3 primary flows:
# - Publish build-specific (commit SHA) based manifest internally
# - Publish edge and release builds manifest internally
# - Promote an existing manifest to a customer release and publish to latest
#
# If no parameters are specified, no manifests are pushed
function print_help() {
  echo "Usage: $0 [OPTION...] <version>"
  echo " --internal: publish SHA tagged manifests internally"
  echo " --edge: publish manifests as edge versions to registry.tld"
  echo " --promote: publish manifests as a promotion (latest and less specific versions) to registry.tld"
  echo " --version=VERSION: specify version number to use"
  echo " --base-version=VERSION: specify base image version number to use to apply tags to"
}

PUBLISH_EDGE=false
PUBLISH_INTERNAL=false
PROMOTE=false
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

IMAGE_NAME="cyberark/conjur"

# Normalize version number in the case of '+' included
VERSION="$(echo -n "${VERSION}" | tr "+" "_")"

# Only push SHA manifests on internal
if [[ "${PUBLISH_INTERNAL}" = true ]]; then
  echo "Creating multi-arch manifest for ${LOCAL_TAG} tagged images in registry.tld..."
  # Always create manifests for SHA versioned images internally
  prepare_manifest "registry.tld/conjur" "${VERSION}-${LOCAL_TAG}"
  prepare_manifest "registry.tld/conjur-test" "${VERSION}-${LOCAL_TAG}"
  prepare_manifest "registry.tld/conjur-ubi" "${VERSION}-${LOCAL_TAG}"

  # Create manifests for SHA only tagged images to our internal registry
  prepare_manifest "registry.tld/conjur" "${LOCAL_TAG}"
  prepare_manifest "registry.tld/conjur-test" "${LOCAL_TAG}"
  prepare_manifest "registry.tld/conjur-ubi" "${LOCAL_TAG}"
fi

if [[ "${PUBLISH_EDGE}" = true ]]; then
  echo "Pushing edge versions..."

  # Publish release specific versions internally
  echo "Creating multi-arch manifest for ${VERSION} in registry.tld..."
  prepare_manifest "registry.tld/${IMAGE_NAME}" "${VERSION}"
  prepare_manifest "registry.tld/conjur-ubi" "${VERSION}"

  # Push manifest to internal registry
  prepare_manifest "registry.tld/${IMAGE_NAME}" "edge"
  prepare_manifest "registry.tld/conjur-ubi" "edge"

  # Publish manifests to dockerhub
  if [[ "${DOCKERHUB}" = true ]]; then
    echo "Pushing to DockerHub"

    prepare_manifest "${IMAGE_NAME}" "${VERSION}"
    prepare_manifest "${IMAGE_NAME}" "edge"
  fi
fi

if [[ "${PROMOTE}" = true ]]; then
  echo "Promoting image to ${VERSION}"

  # Push edge, latest, 1.x.y, 1.x, and 1 manifests
  readarray -t prefix_versions < <(gen_versions "${VERSION}")

  for version in edge latest "${prefix_versions[@]}"; do
    echo "Preparing manifests for tag: $version"
      
    prepare_manifest "registry.tld/${IMAGE_NAME}" "${version}"
    prepare_manifest "registry.tld/conjur-ubi" "${version}"

    # Publish manifests to dockerhub
    if [[ "${DOCKERHUB}" = true ]]; then
      echo "Pushing to DockerHub"

      prepare_manifest "${IMAGE_NAME}" "${version}"
    fi
  done
fi
