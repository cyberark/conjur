#!/bin/bash
set -eo pipefail

check_env_var() {
  if [[ -z "${!1+x}" ]]; then
    # where ${var+x} is a parameter expansion which evaluates to nothing if var is unset, and substitutes the string x otherwise.
    # https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash/13864829#13864829
    echo "You must set $1 before running these scripts."
    exit 1
  fi
}

echo "Checking required environment variables for authn-azure tests"

# These variables should come from Conjur via summon
check_env_var "AZURE_TENANT_ID"
check_env_var "AZURE_SUBSCRIPTION_ID"
check_env_var "AZURE_RESOURCE_GROUP"
check_env_var "AZURE_AUTHN_INSTANCE_USERNAME"
check_env_var "AZURE_AUTHN_INSTANCE_PASSWORD"
check_env_var "USER_ASSIGNED_IDENTITY"
check_env_var "USER_ASSIGNED_IDENTITY_CLIENT_ID"

# These variables should come from Jenkins
check_env_var "AZURE_AUTHN_INSTANCE_IP"
check_env_var "SYSTEM_ASSIGNED_IDENTITY"

echo "Required environment variables for authn-azure tests exist"

