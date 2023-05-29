#!/bin/bash -e

TEST_IMAGE='ruby:3.0'

rm -f Gemfile.lock

docker run --rm \
  -v "$PWD:/usr/src/app" \
  -w /usr/src/app \
  -e CONJUR_ENV=ci \
  $TEST_IMAGE \
  bash -c "gem update --system && bundle update && bundle exec rake spec"
