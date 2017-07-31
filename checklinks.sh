#!/bin/bash -e

# Run html-proofer to check links on the docs site

COMMAND="htmlproofer --check-external-hash --enforce-https --url-ignore '/public/favicon.ico' ./_site"

docker-compose build --pull docs
docker run --rm possum-docs bash -c "$COMMAND"
