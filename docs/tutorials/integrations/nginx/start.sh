#!/usr/bin/env bash

# docker-compose pull
# docker pull svagi/openssl

docker run --rm -it \
       -w /home -v $PWD/tls:/home \
       svagi/openssl req\
       -x509 \
       -nodes \
       -days 365 \
       -newkey rsa:2048 \
       -config /home/tls.conf \
       -extensions v3_ca \
       -keyout nginx.key \
       -out nginx.crt

docker-compose run --no-deps --rm conjur data-key generate > data_key
export CONJUR_DATA_KEY="$(< data_key)"
docker-compose up -d
