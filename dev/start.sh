#!/bin/bash -ex

export COMPOSE_PROJECT_NAME=conjurdev

docker-compose build

if [ ! -f data_key ]; then
	echo "Generating data key"
	docker-compose run --no-deps --rm --entrypoint conjurctl conjur data-key generate > data_key
fi

export CONJUR_DATA_KEY="$(cat data_key)"

docker-compose up -d
docker-compose exec conjur conjurctl db migrate
docker-compose exec conjur conjurctl account create cucumber || true
# docker-compose exec conjur bash
docker exec -it --detach-keys 'ctrl-\' $(docker-compose ps -q conjur) bash
