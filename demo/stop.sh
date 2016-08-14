#!/bin/bash -e

export COMPOSE_PROJECT_NAME=possumdemo

docker-compose stop
docker-compose rm -f
