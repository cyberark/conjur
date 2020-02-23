#!/bin/bash
set -euo pipefail

echo "Retieving Azure access token"
# Get an Azure access token
azure_access_token=$(curl \
  'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' \
  -H Metadata:true -s | jq -r '.access_token')

echo "Get Conjur access token using an Azure access token"
# Get an authn-azure Conjur access token for host azure-apps/test-app
authn_azure_response=$(curl -k -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data "jwt=$azure_access_token" \
  https://"$CONJUR_SERVER_DNS":8443/authn-azure/test/cucumber/host%2Fazure-apps%2Ftest-app/authenticate)
authn_azure_access_token=$(echo -n "$authn_azure_response" | base64 | tr -d '\r\n')

echo "Retrieve a secret using the Conjur access token"
# Retrieve a Conjur secret using the authn-azure Conjur access token
secret=$(curl -k -H "Authorization: Token token=\"$authn_azure_access_token\"" \
  https://"$CONJUR_SERVER_DNS":8443/secrets/cucumber/variable/secrets/test-variable)

echo "Retrieved secret ${secret} from Conjur!!!"
