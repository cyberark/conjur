#!/bin/bash -e

export DEBUG=true
export GLI_DEBUG=true

debify publish $(cat VERSION_APPLIANCE) possum
