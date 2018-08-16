#!/bin/bash

# Functions to generate version numbers for this project

version_tags() {
  # read version to an array
  IFS='.' read -ra VERSION_ARR <<< "$(< VERSION)"

  # set suffix for tags
  HEAD_REF=$(git rev-parse --short HEAD)

  TAGS=()
  for ((i=0; i<${#VERSION_ARR[@]}; i++)); do
    TAG=${VERSION_ARR[0]}

    for ((j=1; j<=$i; j++)); do
      TAG="$TAG.${VERSION_ARR[$j]}"
    done

    TAG="$TAG-$HEAD_REF"

    TAGS+=($TAG)
  done

  # join with comma separator
  IFS=","; shift; echo "${TAGS[*]}";
}
