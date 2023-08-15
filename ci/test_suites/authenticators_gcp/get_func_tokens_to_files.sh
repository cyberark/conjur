#!/bin/bash -ex
# Script that executes several curl requests to a Google cloud function
# to get identity tokens with different audience values and writes them to files

main() {
  echo 'get_func_tokens_to_file'
  validate_pre_requisites || exit 1

  # Read the identity token file
  IDENTITY_TOKEN=$(cat $INFRAPOOL_IDENTITY_TOKEN_FILE)

  sh ./validate_gcf_url_accessible.sh "$GCP_FUNC_URL" "conjur/cucumber/host/test-app" "$IDENTITY_TOKEN" || exit 1
  get_tokens_to_files || exit 1
  echo '-> get_func_tokens_to_file done'
}

validate_pre_requisites() {
  echo 'validate_pre_requisites'
  if [ ! -f "$INFRAPOOL_IDENTITY_TOKEN_FILE" ]; then
    echo "Error: identity token file: '$INFRAPOOL_IDENTITY_TOKEN_FILE' file not found."
    pwd
    ls -l
    exit 1
  fi

  if [ -z "$INFRAPOOL_GCP_PROJECT" ]; then
    echo "-- Error: Google cloud project name is undefined."
    exit 1
  fi

  if [ -z "$GCP_ZONE" ]; then
    echo "-- Error: Google cloud zone is undefined."
    exit 1
  else
   echo "-- Extracting GCP region value"
   echo "-- GCP_ZONE = [$GCP_ZONE]"
   GCP_REGION=$(echo ${GCP_ZONE%-*})
   echo "-- GCP_REGION = [$GCP_REGION]"
  fi

  if [ -z "$INFRAPOOL_GCP_FETCH_TOKEN_FUNCTION" ]; then
    echo "-- Error: Google cloud fetch token name undefined."
    exit 1
  fi

  if [ ! -d "tokens" ]; then
    mkdir tokens || exit 1
  fi

  GCP_FUNC_URL="https://${GCP_REGION}-${INFRAPOOL_GCP_PROJECT}.cloudfunctions.net/${INFRAPOOL_GCP_FETCH_TOKEN_FUNCTION}"
  echo "GCP_FUNC_URL = [$GCP_FUNC_URL]"

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
