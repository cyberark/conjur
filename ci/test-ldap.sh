#!/bin/bash -ex

# shellcheck disable=SC1091

function finish {
  rm -rf cucumber/authn-ldap/features/reports
  docker-compose down --rmi 'local' --volumes
}
trap finish EXIT

cd ..
# Create Conjur Image
./build.sh -j
# Grab the build tag so we launch the correct version of Conjur
. version_utils.sh
export TAG="$(version_tag)"
cd ci

# Setup to allow compose to run in an isolated namespace
export COMPOSE_PROJECT_NAME="$(openssl rand -hex 3)"

# Generate a data key
export CONJUR_DATA_KEY="$(openssl rand -base64 32)"
export COMPOSE_INTERACTIVE_NO_CLI=1
# Start Conjur and supporting services
docker-compose up --no-deps -d conjur pg ldap-server
docker-compose exec conjur conjurctl wait
docker-compose exec conjur conjurctl account create cucumber

mkdir -p cucumber/authenticators/features/reports
rm -rf cucumber/authenticators/features/reports/*

api_key=$(docker-compose exec conjur conjurctl \
  role retrieve-key cucumber:user:admin | tr -d '\r')

docker-compose run --rm -e CONJUR_AUTHN_API_KEY=$api_key cucumber -c \
  'bundle exec rake jenkins:authn_ldap:cucumber'
