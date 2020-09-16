#!/bin/bash -ex

# Script that runs inside a Google SDK container and deploys a function
# That fetches an id token with audience claim passed in the request query string

WORK_DIR="$HOME"
GCF_SOURCE_DIR="$WORK_DIR/function"
GCF_SOURCE_FILE="$GCF_SOURCE_DIR/main.py"

main() {
  echo "Deploy function: $GCF_FUNC_NAME in project: $GCP_PROJECT"
  validate_pre_requisites || exit 1
  deploy_function || exit 1
  write_identity_token_to_file || exit 1
  echo "-> Deploying done"
}

validate_pre_requisites() {
  echo 'validate_pre_requisites'

  if [ -z "$GCP_PROJECT" ]; then
    echo "-- ERROR: function cannot be deployed, GCP project name is undefined."
    exit 1
  fi

  if [ -z "$GCF_FUNC_NAME" ]; then
    echo "-- ERROR: function cannot be deployed, function name is undefined."
    exit 1
  fi

  if [ ! -d "$GCF_SOURCE_DIR" ]; then
    echo "-- ERROR: function cannot be deployed, function directory not found, expected '$GCF_SOURCE_FILE'."
    exit 1
  fi

  if [ ! -f "$GCF_SOURCE_FILE" ]; then
    echo "-- ERROR: function cannot be deployed, function file not found, expected '$GCF_SOURCE_FILE'."
    exit 1
  fi

  if [ ! -f "$GCP_OWNER_SERVICE_KEY" ]; then
    echo "-- ERROR: function cannot be deployed, service account key file not found."
    exit 1
  fi

  echo '-> validate_pre_requisites done'
}

# Deploys a Google function that returns an Identity token with audience that is passed
# as a query string param.
# The function code, is in function/main.py, the function name is unique by the Jenkins build number as suffix.
deploy_function() {
  echo 'deploy_function'

  # Replace the function name with a unique function name in the source code file
  sed -i "s/func_name/$GCF_FUNC_NAME/" "$GCF_SOURCE_FILE"

  # Set the project for the following commands
  gcloud config set project "$GCP_PROJECT"

  # Authenticate using the service account key file
  # NOTE! The script that runs the container with this script provisions the file
  # and the cleanup_function.sh script deletes it.
  gcloud auth activate-service-account --key-file "$GCP_OWNER_SERVICE_KEY"

  # Change dir to function source file
  cd "$GCF_SOURCE_DIR" || exit 1

  echo "-- Deploying function: $GCF_FUNC_NAME"
  gcloud functions deploy "$GCF_FUNC_NAME" --runtime python37 --trigger-http --quiet

  echo '-> deploy_function done'
}

# The Fetch Identity token Google function, is secured, in order to invoke it, the caller
# needs to provide a bearer token in the header of the request.
# This function writes the token to disk, and the clean_function script will delete it,
# in the  post/always branch of the deploy function step.
write_identity_token_to_file() {
  echo 'write_identity_token_to_file'
  cd ..
  echo "-- Write identity-token to file:'$(pwd)/$IDENTITY_TOKEN_FILE'"
  echo  "$(gcloud auth print-identity-token)" > "$IDENTITY_TOKEN_FILE" || exit 1
  echo "Identity token written to file: '$IDENTITY_TOKEN_FILE'."
  echo '-> write_identity_token_to_file done'
}

main || exit 1
