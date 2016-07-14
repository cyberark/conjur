#!/bin/bash -e

docker-compose build

docker-compose up -d pg

sleep 5

if [ ! -f dhparam.pem ]; then
	openssl dhparam 256 -out dhparam.pem
fi

export DH_PARAM_PEM="$(cat dhparam.pem)"

if [ ! -f data_key ]; then
	echo "Generating data key"
	docker-compose run --rm possum data-key generate > data_key
fi

export POSSUM_DATA_KEY="$(cat data_key)"

docker-compose run --rm possum db migrate
docker-compose run --rm possum token-key generate || true

docker-compose up -d
docker-compose logs -f
