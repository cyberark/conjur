#!/bin/bash -ex

# Get an authn-azure Conjur access token for host azure-apps/Ftest-app
authn_azure_response=$(curl -k -X POST \
  https://"$CONJUR_SERVER_DNS":8443/authn-azure/test/cucumber/host%2Fazure-apps%2Ftest-app/authenticate)
authn_azure_access_token=$(echo -n "$authn_azure_response" | base64 | tr -d '\r\n')

# Retrieve a Conjur secret using the authn-azure Conjur access token
curl -k -H "Authorization: Token token=\"$authn_azure_access_token\"" \
  https://"$CONJUR_SERVER_DNS":8443/secrets/cucumber/variable/secrets/test-variable
