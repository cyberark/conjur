#!/bin/bash -e

# Run html-proofer to check links on the docs site

docker-compose build --pull docs

docker run --rm possum-docs htmlproofer \
  --check-external-hash \
  --enforce-https \
  --url-ignore '/public/favicon.ico,/apidocs.html,/api.html#authentication,#' \
  ./_site
