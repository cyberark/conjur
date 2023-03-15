#!/usr/bin/env bash

KEYCLOAK_SERVICE_NAME="keycloak"

# Note: the single arg is a nameref, which this function sets to an array
# containing items of the form "KEY=VAL".
function _hydrate_keycloak_env_args() {
  local -n arr=$1
  local keycloak_items

  readarray -t keycloak_items < <(
    set -o pipefail
    # Note: This prints all lines that look like:
    # KEYCLOAK_XXX=someval
    docker-compose exec -T ${KEYCLOAK_SERVICE_NAME} printenv | awk '/KEYCLOAK/'
  )

  # shellcheck disable=SC2034
  arr=(
    "${keycloak_items[@]}"
    "KEYCLOAK_PROVIDER_URI=https://keycloak:8443/auth/realms/master"
    "PROVIDER_INTERNAL_URI=http://keycloak:8080/auth/realms/master/protocol/openid-connect"
    "PROVIDER_ISSUER=http://keycloak:8080/auth/realms/master"
    "ID_TOKEN_USER_PROPERTY=preferred_username"
  )
}

# The arguments must be unexpanded variable names.  Eg:
#
# _create_keycloak_user '$APP_USER' '$APP_PW' '$APP_EMAIL'
#
# This is because those variables are not available to this script. They are
# available to bash commands run via "docker-compose exec keycloak bash
# -c...", since they're defined in the docker-compose.yml.
function _create_keycloak_user() {
  local user_var=$1
  local pw_var=$2
  local email_var=$3

  docker-compose exec -T \
    ${KEYCLOAK_SERVICE_NAME} \
    bash -c "/scripts/create_user \"$user_var\" \"$pw_var\" \"$email_var\""
}

function create_keycloak_users() {
  echo "Defining keycloak client"

  docker-compose exec -T ${KEYCLOAK_SERVICE_NAME} /scripts/create_client

  echo "Creating user 'alice' in Keycloak"

  # Note: We want to pass the bash command thru without expansion here.
  # shellcheck disable=SC2016
  _create_keycloak_user \
    '$KEYCLOAK_APP_USER' \
    '$KEYCLOAK_APP_USER_PASSWORD' \
    '$KEYCLOAK_APP_USER_EMAIL'

  echo "Creating second user 'bob' in Keycloak"

  # Note: We want to pass the bash command thru without expansion here.
  # shellcheck disable=SC2016
  _create_keycloak_user \
    '$KEYCLOAK_SECOND_APP_USER' \
    '$KEYCLOAK_SECOND_APP_USER_PASSWORD' \
    '$KEYCLOAK_SECOND_APP_USER_EMAIL'

  echo "Creating user in Keycloak that will not exist in conjur"

  # Note: We want to pass the bash command thru without expansion here.
  # shellcheck disable=SC2016
  _create_keycloak_user \
    '$KEYCLOAK_NON_CONJUR_APP_USER' \
    '$KEYCLOAK_NON_CONJUR_APP_USER_PASSWORD' \
    '$KEYCLOAK_NON_CONJUR_APP_USER_EMAIL'
}

function wait_for_keycloak_server() {
  docker-compose exec -T \
    ${KEYCLOAK_SERVICE_NAME} /scripts/wait_for_server
}

function fetch_keycloak_certificate() {
  # there's a dep on the docker-compose.yml volumes.
  # Fetch SSL cert to communicate with keycloak (OIDC provider).
  echo "Initialize keycloak certificate in conjur server"
  docker-compose exec -T \
    conjur /oauth/keycloak/scripts/fetch_certificate
}
