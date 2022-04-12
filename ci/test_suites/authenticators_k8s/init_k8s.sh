#!/bin/bash -ex

# This script is used for developer debugging and isn't part of the main ci flow.
#
# Given platform as a positional argument, the script performs a login to a live K8S cluster.
# Expects environment variables to be passed in via summon.
# After running this script you will be able to perform kubectl/oc operations.
#
# Usage: summon ./init_k8s [platform]
#     gke          login to gcloud cluster
#     openshift    login to OpenShift cluster

# source the init functions
source dev/utils.sh

PLATFORM="$1"

case "$PLATFORM" in
  gke)
    initialize_gke
    ;;
  openshift*)
    initialize_oc
    ;;
  *)
    echo "'$PLATFORM' is not a supported test platform"
    exit 1
esac
