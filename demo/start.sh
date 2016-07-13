#!/bin/bash -e

if [ ! -f dhparam.pem ]; then
	openssl dhparam 256 -out dhparam.pem
fi

if [ ! -f id_rsa ]; then
	echo "Creating token-signing private key"
	ssh-keygen -f ./id_rsa
fi

if [ ! -f data_key ]; then
	echo "Generating data key"
	docker run --rm possum rake generate-data-key > data_key
fi

export POSSUM_DATA_KEY="$(cat data_key)"
export DH_PARAM_PEM="$(cat dhparam.pem)"

docker-compose build
docker-compose up -d pg possum watch ui
