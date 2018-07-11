#!/bin/bash -ex

: <<end_long_comment
compiletemplatescmd <(cat << ENDOFVARIABLES
DOCKER_REGISTRY_PATH=gcr.io/conjur-gke-dev/
ENDOFVARIABLES
)

or

DOCKER_REGISTRY_PATH=gcr.io/conjur-gke-dev/ compiletemplatescmd <(echo '')

or

export DOCKER_REGISTRY_PATH=gcr.io/conjur-gke-dev/
compiletemplatescmd <(echo '')
)
end_long_comment

PROGRAM=$(dirname $(realpath $BASH_SOURCE))/templater.sh

function compiletemplatescmd() {
  if [[ ! -e "$1" ]]; then
    echo "You need to specify a variables file" >&2
    return 1
  fi

  variables=$(cat $1)
  for file in $(find . -iname '*.template.*')
  do
     $PROGRAM $file -f <(echo "$variables") -s > ${file/.template./.$2}
  done
}

function cleanuptemplatescmd() {
  for file in $(find . -iname '*.template.*')
  do
    rm -f ${file/.template./.$1} 2> /dev/null
  done
}
