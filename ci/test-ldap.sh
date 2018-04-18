#!/bin/bash -ex

# shellcheck disable=SC1091

function finish {
  rm -rf cucumber/authn-ldap/features/reports
  docker-compose down --rmi 'local' --volumes
}
# trap finish EXIT

# Setup to allow compose to run in an isolated namespace
export COMPOSE_PROJECT_NAME="$(openssl rand -hex 3)"

# Generate a data key
export CONJUR_DATA_KEY="$(openssl rand -base64 32)"

# Grab the build tag so we launch the correct version of Conjur
cd ..
. version_utils.sh
export TAG="$(version_tag)"
echo "TAG: $TAG"
cd ci

# Start Conjur and supporting services
docker-compose up --no-deps -d conjur pg ldap-server
docker-compose exec conjur conjurctl wait
docker-compose exec conjur conjurctl account create cucumber

mkdir -p cucumber/authn-ldap/features/reports

api_key=$(docker-compose exec conjur conjurctl \
  role retrieve-key cucumber:user:admin | tr -d '\r')

docker-compose run --rm -e CONJUR_AUTHN_API_KEY=$api_key cucumber -c \
  'bundle exec rake jenkins:authn_ldap:cucumber'
