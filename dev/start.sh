#!/bin/bash -ex

function load_ldap_policy {
	api_key=$(docker-compose run --rm conjur-cli
	docker exec conjurdev_conjur_1 bash -c 'rails r "puts Role[%Q{cucumber:user:admin}].api_key" 2>/dev/null')
	docker exec \
		-e CONJUR_AUTHN_API_KEY=$api_key \
		conjurdev_client_1 \
		bash -c 'conjur policy load root /src/conjur-server/dev/sample-ldap-policy.yml'
}

export COMPOSE_PROJECT_NAME=conjurdev

docker-compose build

if [ ! -f data_key ]; then
	echo "Generating data key"
	openssl rand -base64 32 > data_key
fi

export CONJUR_DATA_KEY="$(cat data_key)"

docker-compose up -d
docker-compose exec conjur bundle
docker-compose exec conjur conjurctl db migrate
docker-compose exec conjur conjurctl account create cucumber || true


docker exec -it --detach-keys 'ctrl-\' $(docker-compose ps -q conjur) bash
