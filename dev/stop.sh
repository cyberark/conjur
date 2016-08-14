#!/bin/bash -ex

export COMPOSE_PROJECT_NAME=possumdev

docker-compose stop
docker-compose rm -f
