#!/bin/bash -ex

# shellcheck disable=SC1091
. version_utils.sh

TAGS="$(version_tags)"
IFS=',' read -ra TAGS_ARR <<< "$TAGS"
RUN_DEV=true

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -j|--jenkins)
    RUN_DEV=false
    ;;
    *)
    ;;
esac
shift # past argument or value
done

for tag in "${TAGS_ARR[@]}"; do
  echo "Building image conjur:$tag"
  docker build -t "conjur:$tag" .
done

# we test only the full-build tag (major.minor.build)
FULL_TAG=${TAGS_ARR[${#TAGS_ARR[@]}-1]}
echo "Building image conjur-test:$FULL_TAG container"
docker build --build-arg "VERSION=$FULL_TAG" -t "conjur-test:$FULL_TAG" -f Dockerfile.test .

if [[ $RUN_DEV = true ]]; then
  echo "Building image conjur-dev"
  docker build -t conjur-dev -f dev/Dockerfile.dev .
fi
