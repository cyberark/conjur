#!/bin/bash -ex

docker-compose build

if [ ! -f data_key ]; then
	echo "Generating data key"
	docker-compose run --rm app-dev data-key generate > data_key
fi

export POSSUM_DATA_KEY="$(cat data_key)"

docker-compose up -d pg

docker-compose run --rm --no-deps app-dev
