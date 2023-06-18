#!/bin/bash -e

docker pull registry.tld/conjurinc/publish-rubygem

git clean -fxd

summon --yaml "RUBYGEMS_API_KEY: !var rubygems/api-key" \
  docker run --rm --env-file @SUMMONENVFILE -v "$(pwd)":/opt/src \
  registry.tld/conjurinc/publish-rubygem slosilo

git clean -fxd
