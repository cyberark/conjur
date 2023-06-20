#!/usr/bin/env bash

set -ex

# Builds Conjur Docker images
# Intended to be run from the project root dir
# usage: ./build.sh

# shellcheck disable=SC1091
. build_utils.sh

TAG="$(version_tag)"
jenkins=false # Running on Jenkins (vs local dev machine)

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --jenkins)
    jenkins=true
    ;;
    *)
    ;;
esac
shift # past argument or value
done

# Flatten resulting image.
# This script will rewrite all properties of input image (PORT, ENV, WORKDIR, USER, ENTRYPOINT, CMD)
# instead of hard-coding each of them.
# shellcheck disable=SC2016
function flatten() {
  local image="$1"
  echo "Flattening image '$image'..."
  local container
  container=$(docker create "$image")
  local envs
  envs=$(docker inspect -f '{{range $index, $value := .Config.Env}}{{$value}} {{end}}' "$container")
  local workDir
  workDir=$(docker inspect -f '{{ .Config.WorkingDir }}' "$container")
  local user
  user=$(docker inspect -f '{{ .Config.User }}' "$container")
  local entrypoint
  entrypoint=$(docker inspect -f '[{{range $index, $value := .Config.Entrypoint }}{{if $index}},{{end}}"{{$value}}"{{end}}]' "$container")
  local cmd
  cmd=$(docker inspect -f '[{{range $index, $value := .Config.Cmd }}{{if $index}},{{end}}"{{$value}}"{{end}}]' "$container")
  local ports
  IFS=":" read -r -a ports <<< "$(docker inspect -f '{{range $port, $empty := .Config.ExposedPorts}}--change:EXPOSE {{$port}}:{{end}}' "$container")"
  docker export "$container" | docker import \
    "${ports[@]}" \
    --change "ENV $envs" \
    --change "WORKDIR $workDir" \
    --change "USER ${user:=0}" \
    --change "ENTRYPOINT $entrypoint" \
    --change "CMD $cmd" \
    - "$image"
  docker rm "$container"
}

# Store the current git commit sha in a file so that it can be added to the container.
# This will enable users of the container to determine which revision of conjur
# the container was built from.
git rev-parse HEAD > conjur_git_commit

# We want to build an image:
# 1. Always, when we're developing locally
if [[ $jenkins = false ]]; then
  echo "Building image conjur-dev"
  docker build --tag conjur-dev --file dev/Dockerfile.dev .
  exit 0
fi

# 2. Only if it doesn't already exist, when on Jenkins
image_doesnt_exist() {
  [[ "$(docker images -q "$1" 2> /dev/null)" == "" ]]
}

if image_doesnt_exist "conjur:$TAG"; then
  echo "Building image conjur:$TAG"
  docker build --pull --tag "conjur:$TAG" .
  flatten "conjur:$TAG"
fi

if image_doesnt_exist "conjur-test:$TAG"; then
  echo "Building image conjur-test:$TAG container"
  docker build --build-arg "VERSION=$TAG" --tag "conjur-test:$TAG" --file Dockerfile.test .
fi

if image_doesnt_exist "conjur-ubi:$TAG"; then
  echo "Building image conjur-ubi:$TAG container"
  docker build --pull --build-arg "VERSION=$TAG" --tag "conjur-ubi:$TAG" --file Dockerfile.ubi .
  flatten "conjur-ubi:$TAG"
fi
