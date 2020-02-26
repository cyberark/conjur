#!/bin/bash
set -exuo pipefail

function main() {
    # configure client_id of user identity for Azure instance
    client_id=""

    user_assigned_identity_token_endpoint="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id=$client_id&resource=https%3A%2F%2Fmanagement.azure.com%2F"
    user_assigned_identity_host_name="user-assigned-identity-app"

    # use Azure user-assigned-identity to get Conjur access token
    getConjurTokenWithAzureIdentity $user_assigned_identity_token_endpoint $user_assigned_identity_host_name

    echo "Getting Conjur secret"
    getConjurSecret $conjur_access_token

    system_assigned_identity_token_endpoint="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F"
    system_assigned_identity_host_name="system-assigned-identity-app"

    # use Azure system-assigned-identity to get Conjur access token
    getConjurTokenWithAzureIdentity $system_assigned_identity_token_endpoint $system_assigned_identity_host_name

    echo "Getting Conjur secret"
    getConjurSecret $conjur_access_token
}

function getConjurTokenWithAzureIdentity() {
    azure_token_endpoint="$1"
    conjur_role="$2"

    getAzureAccessToken $azure_token_endpoint $conjur_role

    getConjurToken $azure_access_token
}

function getAzureAccessToken(){
    echo "Retrieving Azure access token from $azure_token_endpoint"
    # Get an Azure access token
    azure_access_token=$(curl \
      "$azure_token_endpoint" \
      -H Metadata:true -s | jq -r '.access_token')
}

function getConjurToken() {
    # Get a Conjur access token for host azure-apps/system-assigned-identity-app or user-assigned-identity-app using the Azure token details
    echo "Get Conjur access token for $conjur_role using its Azure access token"
    authn_azure_response=$(curl -k -X POST \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data "jwt=$azure_access_token" \
      https://"$CONJUR_SERVER_DNS":8443/authn-azure/test/cucumber/host%2Fazure-apps%2F"$conjur_role"/authenticate)

    conjur_access_token=$(echo -n "$authn_azure_response" | base64 | tr -d '\r\n')
}

function getConjurSecret(){
    echo "Retrieve a secret using the Conjur access token"
    # Retrieve a Conjur secret using the authn-azure Conjur access token
    secret=$(curl -k -H "Authorization: Token token=\"$conjur_access_token\"" \
      https://"$CONJUR_SERVER_DNS":8443/secrets/cucumber/variable/secrets/test-variable)

    echo "Retrieved secret ${secret} from Conjur!"
}

main
