#!/bin/bash -ex

export COMPOSE_PROJECT_NAME=possumdev

docker-compose build

if [ ! -f data_key ]; then
	echo "Generating data key"
	docker-compose run --no-deps --rm --entrypoint conjurctl possum data-key generate > data_key
fi

export POSSUM_DATA_KEY="$(cat data_key)"

docker-compose up -d
docker-compose exec possum conjurctl db migrate
docker-compose exec possum conjurctl account create cucumber || true
# docker-compose exec possum bash
docker exec -it --detach-keys 'ctrl-\' $(docker-compose ps -q possum) bash
