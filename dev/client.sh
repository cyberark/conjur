#!/bin/bash -ex

export COMPOSE_PROJECT_NAME=possumdev

docker-compose exec client bash
