#!/bin/bash -ex

debify package \
  possum \
  -- \
  --depends tzdata
