#!/bin/bash -e

export DEBIFY_IMAGE=$(< DEBIFY_IMAGE)
export DEBUG=true
export GLI_DEBUG=true

./docker-debify publish -c stable $(cat VERSION_APPLIANCE) possum
