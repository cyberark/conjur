#!/bin/bash -ex

if [ ! -f data_key ]; then
  echo "Generating data key"
  docker run --rm conjurinc/possum data-key generate > data_key
fi

export POSSUM_DATA_KEY="$(cat data_key)"

echo Launching Postgres service

kubectl create -f dev_pg.yaml

echo Launching Conjur service

kubectl create secret generic conjur-data-key --from-literal "data-key=$POSSUM_DATA_KEY"

kubectl create -f dev_conjur.yaml

kubectl create -f dev_cli.yaml
