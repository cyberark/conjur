#!/bin/bash -ex

docker-compose build

docker-compose up -d pg

docker-compose run --rm --no-deps app-dev
