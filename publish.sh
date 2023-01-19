#!/bin/bash -e

export DEBUG=true
export GLI_DEBUG=true

./docker-debify publish -c stable $(cat VERSION_APPLIANCE) possum
