#!/bin/bash -ex
debify package \
  --dockerfile=Dockerfile.fpm \
  possum \
  -- \
  --depends tzdata
