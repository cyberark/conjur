#!/bin/bash -ex

# Script that executes several curl requests to a Google cloud metadata server
# inside a Google Compute engine node, to get identity tokens with different audience
# values and writes the tokens to files.

get_gce_token_to_files() {
  echo 'get_gce_token_to_files'

  local tokens_info_file="tokens_info.json"
  if [ -f "$tokens_info_file" ]; then
    echo "$tokens_info_file file not found."
    exit 1
  fi

  local tokens="$(cat $tokens_info_file)"
  local token_prefix="gce_"

  for row in $(echo "${tokens}" | jq -c '.[]'); do
    _jq() {
      echo ${row} | jq -r ${1}
    }

    name=$(_jq '.name')
    aud=$(_jq '.audience')
    format=$(_jq '.format')
    [ "$format" = "null" ] && format="full"

    echo "$(retrieve_token $format $aud)" > "$token_prefix$name" || exit 1
  done

  echo '-> get_gce_token_to_files done'
}

retrieve_token() {
  local token_format="$1"
  local audience="$2"
  local metadata_url="http://metadata/computeMetadata/v1/instance/service-accounts/default/identity"

  curl \
    -s \
    -H 'Metadata-Flavor: Google' \
    "$metadata_url?format=${token_format}&audience=${audience}"
}

get_gce_token_to_files

