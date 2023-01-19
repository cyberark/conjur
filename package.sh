#!/bin/bash -ex
export DEBIFY_IMAGE='registry.tld/conjurinc/debify:1.11.5'

docker run --rm $DEBIFY_IMAGE config script > docker-debify
chmod +x docker-debify

./docker-debify package \
  --dockerfile=Dockerfile.fpm \
  possum \
  -- \
  --depends tzdata
