#!/bin/bash -e

export DEBUG=true
export GLI_DEBUG=true

COMPONENT=${1:-possum}

debify publish --component $COMPONENT $(cat VERSION_APPLIANCE) possum
