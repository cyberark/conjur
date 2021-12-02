#!/bin/bash -e

export DEBIFY_IMAGE='registry.tld/conjurinc/debify:one-step-to-ruby3'
export DEBUG=true
export GLI_DEBUG=true

./docker-debify publish -c stable $(cat VERSION_APPLIANCE) possum
