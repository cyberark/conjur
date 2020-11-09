#!/bin/bash
set -eo pipefail


# These variables should come from Conjur via summon
conjur_vars=(
  "AZURE_TENANT_ID"
  "AZURE_SUBSCRIPTION_ID"
  "AZURE_RESOURCE_GROUP"
  "AZURE_AUTHN_INSTANCE_USERNAME"
  "AZURE_AUTHN_INSTANCE_PASSWORD"
  "USER_ASSIGNED_IDENTITY"
  "USER_ASSIGNED_IDENTITY_CLIENT_ID"
)

# These variables should come from Jenkins
jenkins_vars=(
  "AZURE_AUTHN_INSTANCE_IP"
  "SYSTEM_ASSIGNED_IDENTITY"
)

all_required=("${conjur_vars[@]}" "${jenkins_vars[@]}")

missing_vars=()
for var in "${all_required[@]}"; do
  if [[ -z "${!var:+x}" ]]; then
    # where ${var:+x} is a parameter expansion which evaluates to nothing if
    # var is unset, and substitutes the string x otherwise.
    # https://stackoverflow.com/a/13864829
    missing_vars+=("$var")
  fi
done

echo "Checking required environment variables for authn-azure tests..."

if [[ "${#missing_vars[@]}" -gt 0 ]]; then
  printf '%s\n\n' 'The following required env vars are not set:'
  printf "    %s\n" "${missing_vars[@]}"
  exit 1
fi

echo "Done"
