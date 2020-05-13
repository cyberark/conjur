#!/bin/bash -e

export DEBUG=true
export GLI_DEBUG=true

./docker-debify publish $(cat VERSION_APPLIANCE) possum
