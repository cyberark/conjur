#!/bin/bash -ex

export COMPOSE_PROJECT_NAME=conjurdev

api_key=$(docker-compose exec conjur conjurctl role retrieve-key cucumber:user:admin | tr -d '\r')
docker-compose run --rm -e CONJUR_AUTHN_API_KEY=$api_key --entrypoint /bin/bash client -c '
  conjur policy load root /src/conjur-server/dev/sample-ldap-policy.yml
'
