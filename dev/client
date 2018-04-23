#!/bin/bash -ex

export COMPOSE_PROJECT_NAME=conjurdev

docker exec -it --detach-keys 'ctrl-\' $(docker-compose ps -q client) bash
#docker-compose exec client bash
