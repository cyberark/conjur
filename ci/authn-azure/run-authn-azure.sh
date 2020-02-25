#!/bin/bash
set -exuo pipefail

function main() {
    # configure client_id of user identity for Azure instance
    client_id=""

    user_endpoint="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id=$client_id&resource=https%3A%2F%2Fmanagement.azure.com%2F"
    conjur_host_user_identity="user-app"

    system_endpoint="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F"
    conjur_host_system_identity="test-app"

    getConjurSecret $user_endpoint $conjur_host_user_identity
    getConjurSecret $system_endpoint $conjur_host_system_identity
}

function getConjurSecret() {
    azure_token_endpoint="$1"
    conjur_role="$2"
    echo $azure_token_endpoint
    echo "Retrieving Azure access token"
    # Get an Azure access token
    azure_access_token=$(curl \
      "$azure_token_endpoint" \
      -H Metadata:true -s | jq -r '.access_token')

    echo "Get Conjur access token using an Azure access token"
    # Get an authn-azure Conjur access token for host azure-apps/test-app and user-app
    authn_azure_response=$(curl -k -X POST \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data "jwt=$azure_access_token" \
      https://"$CONJUR_SERVER_DNS":8443/authn-azure/test/cucumber/host%2Fazure-apps%2F"$conjur_role"/authenticate)
    authn_azure_access_token=$(echo -n "$authn_azure_response" | base64 | tr -d '\r\n')

    echo "Retrieve a secret using the Conjur access token"
    # Retrieve a Conjur secret using the authn-azure Conjur access token
    secret=$(curl -k -H "Authorization: Token token=\"$authn_azure_access_token\"" \
      https://"$CONJUR_SERVER_DNS":8443/secrets/cucumber/variable/secrets/test-variable)

    echo "Retrieved secret ${secret} from Conjur!!!"
}

main