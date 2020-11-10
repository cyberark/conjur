#!/usr/bin/env bash

# Functions to generate version numbers for this project

version_tag() {
  echo "$(< VERSION)-$(git rev-parse --short=8 HEAD)"
}

# generate less specific versions, eg. given 1.2.3 will print 1.2 and 1
# (note: the argument itself is not printed, append it explicitly if needed)
gen_versions()
{
  local version=$1
  while [[ $version = *.* ]]; do
    version=${version%.*}
    echo $version
  done
}
