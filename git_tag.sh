#!/bin/bash

# Gets the version string of the current HEAD without the `v` prefix.
git_tag() {
  local GIT_TAG="$(git describe --abbrev $1)"
  echo "${GIT_TAG#v}"
}
