#!/bin/bash -ex

docker-compose build

if [ ! -f data_key ]; then
  echo "Generating data key"
  docker-compose run --no-deps --rm possum data-key generate > data_key
fi

export POSSUM_DATA_KEY="$(cat data_key)"

docker-compose up -d pg possum
docker-compose run --rm client
