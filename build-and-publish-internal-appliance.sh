#!/usr/bin/env bash
set -euo pipefail


IMAGE="registry.tld/conjur-appliance:eval-authn-k8s-label-selector"

docker build -f ./Dockerfile.appliance -t "${IMAGE}" .
docker push "${IMAGE}"
