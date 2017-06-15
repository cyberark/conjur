#!/bin/bash -ex

export COMPOSE_PROJECT_NAME=possumpagesdev

docker-compose stop
docker-compose rm -f
