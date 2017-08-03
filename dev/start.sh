#!/bin/bash -ex

export COMPOSE_PROJECT_NAME=possumdev

docker-compose build

if [ ! -f data_key ]; then
	echo "Generating data key"
	docker-compose run --no-deps --rm --entrypoint conjurd possum data-key generate > data_key
fi

export POSSUM_DATA_KEY="$(cat data_key)"

docker-compose up -d
docker-compose exec possum conjurd db migrate
docker-compose exec possum conjurd account create cucumber || true
# docker-compose exec possum bash
docker exec -it --detach-keys 'ctrl-\' $(docker-compose ps -q possum) bash
