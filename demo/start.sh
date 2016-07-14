#!/bin/bash -e

if [ ! -f dhparam.pem ]; then
	openssl dhparam 256 -out dhparam.pem
fi

if [ ! -f data_key ]; then
	echo "Generating data key"
	docker-compose run --rm possum data-key generate > data_key
fi

docker-compose run --rm possum token-key generate || true

export POSSUM_DATA_KEY="$(cat data_key)"
export DH_PARAM_PEM="$(cat dhparam.pem)"

docker-compose build
docker-compose up -d pg possum watch ui
