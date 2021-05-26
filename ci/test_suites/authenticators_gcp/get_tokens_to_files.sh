#!/bin/bash -ex

# Tokens are generated and consumed in multiple tests (gce, gce, dev/start).
# tokens_config.json file, holds the tokens list and definitions.
# Token definitions are: name, audience, format if applicable (when format is omitted the default is full).
_get_token_to_files() {
  echo '_get_token_to_files'
  local url="$1"
  local token_prefix="$2"
  local add_format="$3"
  local auth_token="$4"

  if [ -z "$url" ]; then
      "ERROR: url argument is missing."
      exit 1
  fi

  if [ -z "$token_prefix" ]; then
      "ERROR: token_prefix argument is missing."
      exit 1
  fi

  local tokens_config_file="tokens_config.json"
  if [ ! -f "$tokens_config_file" ]; then
    echo "Tokens config file: '$tokens_config_file', file not found."
    exit 1
  fi

  # Read the tokens definitions file
  local tokens="$(cat $tokens_config_file)"


  # Iterate over the tokens definitions and for each definition create a token
  # with the name, audience and format specified in the definition.
  for row in $(echo "${tokens}" | jq -c '.[]'); do
    _jq() {
      echo ${row} | jq -r ${1}
    }
    # Extract name and audience from JSON node
    name=$(_jq '.name')
    aud=$(_jq '.audience')


    # Start formatting the token url
    local token_url="$url?audience=${aud}"

    # Add format to query string if applicable
    if [ "$add_format" = "true" ]; then
      format=$(_jq '.format')

      # When format is omitted the default is full
      [ "$format" = "null" ] && format="full"
      token_url="$token_url&format=$format"
    fi

    # Write the token to file
    echo "-- Obtain an ID token from function url: '$token_url' and write to file: '$token_prefix$name'"

    local token=""

    if [ -z "$auth_token" ]; then
      token="$(curl -L -s -H 'Metadata-Flavor: Google' $token_url)" || exit 1
    else
      token=$(curl -L -s \
      -H "Authorization: bearer $auth_token" \
      -H 'Metadata-Flavor: Google' "$token_url") || exit 1
    fi

    echo "$token" > "$token_prefix$name" || exit 1
  done

  echo '-> _get_token_to_files done'
}

_get_token_to_files "$1" "$2" "$3" "$4" || exit 1

