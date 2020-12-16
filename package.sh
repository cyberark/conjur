#!/bin/bash -ex
export DEBIFY_IMAGE='registry.tld/conjurinc/debify:2.0.0'

docker run --rm $DEBIFY_IMAGE config script > docker-debify
chmod +x docker-debify

# Creates possum deb
./docker-debify package \
  --dockerfile=Dockerfile.fpm \
  --output=deb
  possum \
  -- \
  --depends tzdata
  --force

# Creates possum rpm
./docker-debify package \
  --dockerfile=Dockerfile.fpm \
  --output=rpm
  possum \
  -- \
  --depends tzdata
  --force
