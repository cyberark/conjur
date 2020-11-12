#!/bin/bash -ex

# Script that runs a Google SDK container and executes a script argument.

# The name of the script to run in the Google SDK container.
GCLOUD_SCRIPT=$1

finish() {
  verify_sa_key_file_deleted
}
trap finish EXIT

main() {
  echo "run_gcloud.sh with script: $GCLOUD_SCRIPT"
  validate_pre_requisites
  write_sa_key_to_file
  run_gcloud_container
  echo "-> run_gcloud.sh with script: $GCLOUD_SCRIPT done"
}

validate_pre_requisites() {
  echo 'validate_pre_requisites'

  if [ -z "$GCLOUD_SCRIPT" ]; then
    echo "-> Missing script file name argument"
    exit 1
  fi

  if [ -z "$GCP_OWNER_SERVICE_KEY" ]; then
    echo "-- env var 'GCP_OWNER_SERVICE_KEY' is undefined"
    exit 1
  fi

  if [ -z "$GCP_OWNER_SERVICE_KEY_FILE" ]; then
    echo "-- env var 'GCP_OWNER_SERVICE_KEY_FILE' is undefined"
    exit 1
  fi

  if [ -z "$GCP_FETCH_TOKEN_FUNCTION" ]; then
    echo "-- env var 'GCP_FETCH_TOKEN_FUNCTION' is undefined"
    exit 1
  fi

  if [ -z "$GCP_PROJECT" ]; then
    echo "-- env var 'GCP_PROJECT' is undefined"
    exit 1
  fi

  if [ -z "$IDENTITY_TOKEN_FILE" ]; then
    echo "-- env var 'IDENTITY_TOKEN_FILE' is undefined"
    exit 1
  fi
  echo '-> validate_pre_requisites done'
}

# Authentication with Google CLI requires the service account key as file on disk.
# This function writes the key that gets provisioned by summon temporary to disk, the cleanup_function.sh script
# will delete it in the post/always branch of the stage.
# The file is used by both by the deploy and clean function scripts.
write_sa_key_to_file() {
  echo 'write_sa_key_to_file'
  if [ ! -f "$GCP_OWNER_SERVICE_KEY" ]; then
    echo "-- Write account service key to file: '$GCP_OWNER_SERVICE_KEY_FILE' (required for gcloud auth)"
    echo "$GCP_OWNER_SERVICE_KEY" > "$GCP_OWNER_SERVICE_KEY_FILE"
  fi
  echo '-> write_sa_key_to_file done'
}

# Runs a Google SDK container and invokes the script argument.
run_gcloud_container() {
  echo "run_gcloud_container"

  local local_volume="$(pwd)"
  local container_volume="/root"
  local google_sdk_image=gcr.io/google.com/cloudsdktool/cloud-sdk:slim
  local cmd=".$container_volume/$GCLOUD_SCRIPT"

  docker run \
    -e GCF_FUNC_NAME="$GCP_FETCH_TOKEN_FUNCTION" \
    -e GCP_PROJECT="$GCP_PROJECT" \
    -e GCP_OWNER_SERVICE_KEY="$container_volume/$GCP_OWNER_SERVICE_KEY_FILE" \
    -e IDENTITY_TOKEN_FILE="$IDENTITY_TOKEN_FILE" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --rm -i -v "$local_volume":"$container_volume" "$google_sdk_image" "$cmd"

  echo "-> run_gcloud_container done"
}

# Deletes the service account key file if still exists
# Service account key file is used to authenticate with Google SDK CLI.
# Google SDK CLI (gcloud) is used to deploy the Google function.
verify_sa_key_file_deleted() {
  if [ -f "$GCP_OWNER_SERVICE_KEY_FILE" ]; then
    echo "Error: Container didn't take care to delete key file after usage"
    rm -f echo "$GCP_OWNER_SERVICE_KEY_FILE"
  fi
}

main
