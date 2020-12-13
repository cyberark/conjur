#!/bin/bash

DOCKER_USER=$1

docker buildx build -t $DOCKER_USER/conjur:latest \
  --build-arg DOCKER_USER="$DOCKER_USER" \
  --platform linux/amd64,linux/arm64 .  --push
