#!/bin/bash -ex

# Script that executes several curl requests to a Google cloud metadata server
# inside a Google Compute engine node, to get identity tokens with different audience
# values and writes the tokens to files.

get_gce_token_to_files() {
  echo 'get_gce_token_to_files'
  local token_prefix=gce

  echo "$(retrieve_token "full" "conjur/cucumber/host/test-app")" > "${token_prefix}_token_valid" || exit 1
  echo "$(retrieve_token "full" "conjur/cucumber/host/non-existing")" > "${token_prefix}_token_non_existing_host" || exit 1
  echo "$(retrieve_token "full" "conjur/cucumber/host/non-rooted/test-app")" > "${token_prefix}_token_non_rooted_host" || exit 1
  echo "$(retrieve_token "full" "conjur/cucumber/test-app")" > "${token_prefix}_token_user" || exit 1
  echo "$(retrieve_token "full" "conjur/non-existing/host/test-app")" > "${token_prefix}_token_non_existing_account" || exit 1
  echo "$(retrieve_token "full" "invalid_audience")" > "${token_prefix}_token_invalid_audience" || exit 1
  echo "$(retrieve_token "standard" "conjur/cucumber/host/test-app")" > "${token_prefix}_token_standard_format" || exit 1
  echo '-> get_gce_token_to_files done'
}

retrieve_token() {
  local token_format="$1"
  local audience="$2"

  curl \
    -s \
    -H 'Metadata-Flavor: Google' \
    "http://metadata/computeMetadata/v1/instance/service-accounts/default/identity?format=${token_format}&audience=${audience}"
}

get_gce_token_to_files

