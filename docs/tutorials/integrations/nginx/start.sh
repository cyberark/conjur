#!/usr/bin/env bash

# docker-compose pull
# docker pull svagi/openssl

rm -f tls/nginx.key tls/nginx.crt
docker-compose down

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

sleep 6

docker-compose exec conjur conjurctl account create test | tee test.out
api_key="$(grep API test.out | cut -d: -f2 | tr -d ' \r\n')"

docker-compose exec client bash -c "echo yes | conjur init -u https://proxy -a test"
docker-compose exec client conjur authn login -u admin -p "$api_key"
