#!/bin/bash -e

export COMPOSE_PROJECT_NAME=possumdemo

docker-compose build

# This is only here to speed up the UI launch time.
if [ ! -f dhparam.pem ]; then
	openssl dhparam 256 -out dhparam.pem
fi

export DH_PARAM_PEM="$(cat dhparam.pem)"

if [ ! -f data_key ]; then
	echo "Generating data key"
	docker-compose run --rm possum data-key generate > data_key
fi

export POSSUM_DATA_KEY="$(cat data_key)"

docker-compose up -d
docker-compose logs -f
