#!/bin/bash -ex

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
docker-compose exec conjur conjurctl account create cucumber

docker exec -it --detach-keys 'ctrl-\' $(docker-compose ps -q conjur) bash
