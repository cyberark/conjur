#!/bin/bash -e

export DEBIFY_IMAGE=$(< DEBIFY_IMAGE)
export DEBUG=true
export GLI_DEBUG=true

./docker-debify publish --version "$(<VERSION)" -c stable "$(cat VERSION_APPLIANCE)" possum
