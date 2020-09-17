#!/bin/bash -ex
# Script that executes several curl requests to a Google cloud function
# to get identity tokens with different audience values and writes them to files

GCP_FUNC_URL="https://${GCP_ZONE}-${GCP_PROJECT}.cloudfunctions.net/${GCP_FETCH_TOKEN_FUNCTION}"

main() {
  echo 'get_func_tokens_to_file.sh'
  validate_pre_requisites || exit 1

  # Read the identity token file
  IDENTITY_TOKEN=$(cat $IDENTITY_TOKEN_FILE)

  test_token_function "conjur/cucumber/host/test-app" || exit 1
  get_tokens_to_file || exit 1
  echo '-> get_func_tokens_to_file.sh done'
}

validate_pre_requisites() {
  echo 'validate_pre_requisites'
  if [ ! -f "$IDENTITY_TOKEN_FILE" ]; then
    echo "Error: identity token file: '$IDENTITY_TOKEN_FILE' file not found."
    pwd
    ls -l
    exit 1
  fi

  if [ -z "$GCP_PROJECT" ]; then
    echo "-- Error: Google cloud project name is undefined."
    exit 1
  fi

  if [ -z "$GCP_ZONE" ]; then
    echo "-- Error: Google cloud zone is undefined."
    exit 1
  fi

  if [ -z "$GCP_FETCH_TOKEN_FUNCTION" ]; then
    echo "-- Error: Google cloud fetch token name undefined."
    exit 1
  fi

  if [ ! -d "tokens" ]; then
    mkdir tokens || exit 1
  fi
  echo '-> validate_pre_requisites done'
}

# Invokes the function once to test if the function is accessible.
test_token_function() {
  echo 'test_token_function'
  local audience="$1"
  local status_code=$(curl -o /dev/null -s -w "%{http_code}\n" \
    -H "Authorization: bearer $IDENTITY_TOKEN" \
    -H 'Metadata-Flavor: Google' "$GCP_FUNC_URL?audience=${audience}")

  if [ ! "$status_code" = "200" ]; then
    echo "-- Function returned error, HTTP Status: '${status_code}', \
    cannot obtain token from URL: $GCP_FUNC_URL?audience=${audience}"
    exit 1
  fi
  echo '-> test_token_function done'
}

# Invokes the function with different audience
# values and writes the tokens to disk.
get_tokens_to_file() {
  echo 'get_tokens_to_file'
  local tokens_info_file="tokens_info.json"
  if [ -f "$tokens_info_file" ]; then
    echo "$tokens_info_file file not found."
    exit 1
  fi

  # Tokens file path prefix
  local token_dir="tokens"
  local token_prefix="gcf_"
  local tokens="$(cat $tokens_info_file)"

  for row in $(echo "${tokens}" | jq -c '.[]'); do
    _jq() {
      echo ${row} | jq -r ${1}
    }

    name=$(_jq '.name')
    aud=$(_jq '.audience')

    echo "$(retrieve_token $aud)" > "$token_dir/$token_prefix$name" || exit 1
  done

  echo '-> get_tokens_to_file done'
}

# Invokes Google function with $audience as argument
# and $IDENTITY_TOKEN as bearer token.
retrieve_token() {
  local audience="$1"
  echo "-- Obtain token from URL: $GCP_FUNC_URL?audience=$audience"

  curl \
    -s \
    -H 'Metadata-Flavor: Google' \
    -H "Authorization: bearer $IDENTITY_TOKEN" \
    "$GCP_FUNC_URL?audience=${audience}"
}

main || exit 1
