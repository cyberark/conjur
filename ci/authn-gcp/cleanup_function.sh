#!/bin/bash -ex

# Script that runs inside a Google SDK container and deletes the fetch id function
# that was deployed in the deploy_function script.

cleanup_function() {
  echo "-- Cleanup function"
  validate_pre_requisites
  delete_function
  delete_identity_token
  echo "-- Cleanup function done"
}

validate_pre_requisites() {
  echo 'validate_pre_requisites'
  if [ -z "$GCP_PROJECT" ]; then
    echo "ERROR: function cannot be deleted, GCP project name is undefined."
    exit 1
  fi

  if [ -z "$GCF_FUNC_NAME" ]; then
    echo "ERROR: function cannot be deleted, function name is undefined."
    exit 1
  fi

  if [ ! -f "$GCP_OWNER_SERVICE_KEY" ]; then
    echo "ERROR: function cannot be deleted, service account key file not found."
    exit 1
  fi
  echo '-> validate_pre_requisites done'
}

delete_function() {
  echo "Delete function: $GCF_FUNC_NAME in project: $GCP_PROJECT"

  # Set the project for the following commands
  gcloud config set project "$GCP_PROJECT"

  # Authenticate using the service account key file
  # NOTE! The script that runs the container with this script provisions the file
  # and this script deletes it.
  gcloud auth activate-service-account --key-file "$GCP_OWNER_SERVICE_KEY"

  # delete key soon after done using - due to security concerns
  rm -f "$GCP_OWNER_SERVICE_KEY"

  # List all functions and filter the $GCF_FUNC_NAME variable
  local func_exists="gcloud functions list --format='value(name)' --filter='name ~ $GCF_FUNC_NAME'"

  if [ -n "$func_exists" ]; then
    echo "-- Delete function: '$GCF_FUNC_NAME'."
    gcloud functions delete "$GCF_FUNC_NAME" --quiet
  fi
  echo "-> Delete function done"
}

# Deletes the Google identity token file that was used to access the Google function.
# The function does not allow unauthenticated access.
# The Google identity token is used to invoke the function, the token is passed
# in the request header as bearer token.
delete_identity_token() {
  echo 'delete_identity_token'
  local token_file="$HOME/$IDENTITY_TOKEN_FILE"
  echo "Delete identity-token file: '$token_file'"

  if [ -f "$token_file" ]; then
    rm -f "$token_file"
    echo "identity-token file: '$token_file' deleted"
  else
    echo "Warning: cannot delete identity token file: '$token_file', file not found."
  fi
  echo '-> delete_identity_token done'
}

cleanup_function || exit 1
