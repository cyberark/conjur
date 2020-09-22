#!/bin/bash -ex
# Script that executes several curl requests to a Google cloud function
# to get identity tokens with different audience values and writes them to files

GCP_FUNC_URL="https://${GCP_ZONE}-${GCP_PROJECT}.cloudfunctions.net/${GCP_FETCH_TOKEN_FUNCTION}"

main() {
  echo 'get_func_tokens_to_file'
  validate_pre_requisites || exit 1

  # Read the identity token file
  IDENTITY_TOKEN=$(cat $IDENTITY_TOKEN_FILE)

  sh ./validate_gcf_url_accessible.sh "$GCP_FUNC_URL" "conjur/cucumber/host/test-app" "$IDENTITY_TOKEN" || exit 1
  get_tokens_to_files || exit 1
  echo '-> get_func_tokens_to_file done'
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

# Invokes the function with different audience
# values and writes the tokens to disk.
get_tokens_to_files() {
  echo 'get_tokens_to_file'

  local token_prefix="tokens/gcf_"
  # format is not applicable in function token.
  local add_format="false"

  sh ./get_tokens_to_files.sh "$GCP_FUNC_URL" "$token_prefix" \
  "$add_format" "$IDENTITY_TOKEN" || 1

  echo '-> get_tokens_to_file done'
}


main || exit 1
