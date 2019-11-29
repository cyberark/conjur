#!/bin/bash

# Script to run generate_report.rb within docker so that the gems don't
# need to be installed locally.
# generate_report.rb generates an html report from simplecov json output.

set -xeu

repo_root=$(git rev-parse --show-toplevel)
# Use the first arg, or if not supplied use the simplecov default report location
report_file="${1:-${repo_root}/coverage/.resultset.json}"
image="ruby:2.6.5-stretch"

docker run \
    --rm \
    -v "${repo_root}":"${repo_root}" \
    -w "${repo_root}/ci/coverage-report-generator" \
    "${image}" \
        bash -cx "bundle install --path gems
                  bundle list
                  bundle exec ./generate_report.rb \
                     ${repo_root} \
                     ${report_file}
                 "