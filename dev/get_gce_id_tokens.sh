#!/bin/bash

# This script obtains all of the GCE identity tokens required by authn-gce cucumber tests
# The scripts accepts the GCE instance name as an argument and an optional GCP zone (default is us-central1-a).
# The script does the following:
# 1. Validates gcloud is installed (requires a GCP account)
#   To install gcloud goto: https://cloud.google.com/sdk/docs, download and install the SDK by running:
#   ./google-cloud-sdk/install.sh
#   ./google-cloud-sdk/bin/gcloud init
# 2. Verifies the GCE instance exists and is in status running
# 3. Executes a ssh curl command and write the output token with the appropriate token name to '../ci/authn-gce/tokens'.

PROGNAME=$(basename $0)
GCE_ZONE=us-central1-a
TOKENS_OUT_DIR_PATH=../ci/authn-gce/tokens
INSTANCE_EXISTS=0
INSTANCE_RUNNING=0

error_exit()
{
  #	----------------------------------------------------------------
  #	Function for exit due to fatal program error
  #		Accepts 1 argument:
  #			string containing descriptive error message
  #	----------------------------------------------------------------

	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit 1
	echo "$1" 1>&2
	exit 1
}

get_token_into_file() {
  local token_format="$1"
  local audience="$2"
  local filename="$3"
  local curl_cmd="curl -s -H 'Metadata-Flavor: Google' \
    'http://metadata/computeMetadata/v1/instance/service-accounts/default/identity?format=${token_format}&audience=${audience}'"
  echo "-- write token in ${token_format} format with audience: ${audience} to ${TOKENS_OUT_DIR_PATH}/${filename}"
  gcloud compute ssh $INSTANCE_NAME --zone=$GCE_ZONE --command "${curl_cmd}" >"${TOKENS_OUT_DIR_PATH}/${filename}" &
}

get_tokens_into_files() {
  if  [ "${INSTANCE_EXISTS}" = "0" ] | [ "${INSTANCE_RUNNING}" = "0" ] ; then
    error_exit "-- Cannot run command, GCE instance '${INSTANCE_NAME}' not in valid state!"
  else
    get_token_into_file "full" "conjur%2Fcucumber%2Fhost%2Ftest-app" "gce_token_valid"
    get_token_into_file "full" "conjur%2fcucumber%2fhost%2fnon-existing" "gce_token_non_existing_host"
    get_token_into_file "full" "conjur%2fcucumber%2fhost%2fnon-rooted%2ftest-app" "gce_token_non_rooted_host"
    get_token_into_file "full" "conjur%2fcucumber%2ftest-app" "gce_token_user"
    get_token_into_file "full" "conjur%2fnon-existing%2fhost%2ftest-app" "gce_token_non_existing_account"
    get_token_into_file "full" "invalid_audience" "gce_token_invalid_audience"
    get_token_into_file "standard" "conjur%2fcucumber%2fhost%2ftest-app" "gce_token_standard_format"
    wait
  fi
}

check_if_gce_instance_is_running() {
  if [ "${INSTANCE_EXISTS}" = "1" ]; then
    if gcloud compute instances describe "${INSTANCE_NAME}" --zone=$GCE_ZONE --format="yaml(status)" | grep -q "status: RUNNING"; then
      echo "-- Instance '${INSTANCE_NAME}' is running..."
      INSTANCE_RUNNING=1
    else
      error_exit "-- Instance '${INSTANCE_NAME}' is NOT running!"
    fi
  else
    error_exit "-- WARNING! Google Compute Engine instance: '${INSTANCE_NAME}' not found!"
  fi
}

check_if_gce_instance_exists() {
  if gcloud compute instances list --zones="${GCE_ZONE}" --format="csv(name)" | grep -q $INSTANCE_NAME; then
    echo "-- GCE instance '${INSTANCE_NAME}' found."
    INSTANCE_EXISTS=1
  else
    error_exit "GCE instance '${INSTANCE_NAME}' NOT found!"
  fi
}


set_zone() {
  if [ -z "$1" ]; then
    echo "-- Using default zone '${GCE_ZONE}'"
  else
    GCE_ZONE=$(sed 's/.*=//' <<< $1)
    echo "-- Using zone '${GCE_ZONE}'"
  fi
}

check_instance_name_arg() {
  if [ -z "$1" ]; then
    echo "${PROGNAME}: ${LINENO} GCE instance name is required. Usage: ./${PROGNAME} GCE_INSTANCE_NAME"
    gcloud compute instances list --zones=$GCE_ZONE --format="table[box,title='Instances in zone: $GCE_ZONE'](name,machine_type.basename(),status)"
    exit 1
  else
    INSTANCE_NAME=$1
    echo "-- GCE instance name is set to: '${INSTANCE_NAME}'."
  fi
}

ensure_gcloud_is_installed() {
  COMMAND=gcloud

  if ! command -v $COMMAND &>/dev/null; then
    error_exit "-- ${COMMAND} could not be found."
  fi
  echo "-- ${COMMAND} command exists"
}

main() {
  echo "-- ------------------------------------------ --"
  echo "-- Generate Google Cloud GCE Identity tokens --"
  echo "-- ------------------------------------------ --"

  echo "-- Verifying 'gcloud' is installed..."
  ensure_gcloud_is_installed
  echo "-- Verifying CGE instance name..."
  check_instance_name_arg $1
  echo "-- Setting CGE zone..."
  set_zone $2
  echo "-- Checking if GCE instance: '${INSTANCE_NAME}' exists..."
  check_if_gce_instance_exists
  echo "-- Checking if GCE instance: '${INSTANCE_NAME}' in status running..."
  check_if_gce_instance_is_running
  echo "-- Generate tokens and writing to files under '${TOKENS_OUT_DIR_PATH}'..."
  get_tokens_into_files
  echo "-- Done."
}

main $1 $2