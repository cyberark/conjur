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
  echo " --ecr: publish images to Amazon ECR"
}

PUBLISH_INTERNAL=false
VERSION=$(<VERSION)
PUBLISH_ECR=false

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
    --ecr )
      PUBLISH_ECR=true
      shift
      ;;
    * )
      echo "Unknown option: ${arg}"
      print_help
      exit 1
      ;;
    esac
done

LOCAL_IMAGE="conjur-cloud:${LOCAL_TAG}"

# Normalize version number in the case of '+' included
VERSION="$(echo -n "${VERSION}" | tr "+" "_")"

# Only push SHA images on internal
if [[ "${PUBLISH_INTERNAL}" = true ]]; then
  echo "Pushing ${LOCAL_TAG} tagged images to registry.tld..."
  # Always push SHA versioned images internally
  tag_and_push "${VERSION}-${LOCAL_TAG}" "${LOCAL_IMAGE}" "registry.tld/conjur-cloud"
  tag_and_push "${VERSION}-${LOCAL_TAG}" "conjur-test:${LOCAL_TAG}" "registry.tld/conjur-test"
#  tag_and_push "${VERSION}-${LOCAL_TAG}" "conjur-ubi-cloud:${LOCAL_TAG}" "registry.tld/conjur-ubi-cloud"

  # Push SHA only tagged images to our internal registry
  tag_and_push "${LOCAL_TAG}" "${LOCAL_IMAGE}" "registry.tld/conjur-cloud"
  tag_and_push "${LOCAL_TAG}" "conjur-test:${LOCAL_TAG}" "registry.tld/conjur-test"
#  tag_and_push "${LOCAL_TAG}" "conjur-ubi-cloud:${LOCAL_TAG}" "registry.tld/conjur-ubi-cloud"  
fi

# If --ecr option is provided, push the image to Amazon ECR
if [[ "${PUBLISH_ECR}" = true ]]; then
  echo "Pushing ${LOCAL_IMAGE} tagged image to Amazon ECR..."

  # Set the temporary credentials as environment variables for the duration of the script
  export AWS_ACCESS_KEY_ID=$INFRAPOOL_AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$INFRAPOOL_AWS_SECRET_ACCESS_KEY
  TAG_LATEST=false
  ECR_REGION="us-east-1"
  ECR_REGISTRY="238637036211.dkr.ecr.us-east-1.amazonaws.com"
  ECR_REPO_NAME="mgmt-conjur-dev-repository-conjur"

  aws sts get-caller-identity

    # Authenticate Docker with Amazon ECR
  aws ecr get-login-password --region "${ECR_REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

  # Set tags based on branch name
  if [[ "${BRANCH_NAME}" == 'ONYX-60667' ]]; then
    TAG="${VERSION}"
    TAG_LATEST=true
  else
    TAG="${VERSION}.${BRANCH_NAME}-${BUILD_NUMBER}"
  fi

  # Tag and push the built image to Amazon ECR
  docker tag "${LOCAL_IMAGE}" "${ECR_REGISTRY}/${ECR_REPO_NAME}:${TAG}"
  docker push "${ECR_REGISTRY}/${ECR_REPO_NAME}:${TAG}"
  docker images

  if [[ "${TAG_LATEST}" = true ]]; then
    MANIFEST=$(aws ecr batch-get-image --region "${ECR_REGION}" --repository-name "${ECR_REPO_NAME}" --image-ids imageTag="${TAG}" --output text --query 'images[].imageManifest')
    echo "Manifest: ${MANIFEST}"
    aws ecr put-image --region "${ECR_REGION}" --repository-name "${ECR_REPO_NAME}" --image-tag "ldtest" --image-manifest "${MANIFEST}"
    aws ecr describe-images --region "${ECR_REGION}" --repository-name "${ECR_REPO_NAME}" --image-ids imageTag="ldtest"
  fi

  # Clean up by unsetting the temporary credentials
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
fi
