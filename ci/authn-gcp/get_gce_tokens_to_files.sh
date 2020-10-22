#!/bin/bash -ex

# Script that executes several curl requests to a Google cloud metadata server
# inside a Google Compute engine node, to get identity tokens with different audience
# values and writes the tokens to files.
get_gce_token_to_files() {
  echo 'get_gce_token_to_files'

  local metadata_url="http://metadata/computeMetadata/v1/instance/service-accounts/default/identity"
  local token_prefix="gce_"
  local add_format="true"

  sh ./get_tokens_to_files.sh "$metadata_url" "$token_prefix" "$add_format" || exit 1

  echo '-> get_gce_token_to_files'
}

get_gce_token_to_files || exit 1

