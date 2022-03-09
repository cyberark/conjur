#!/usr/bin/env bash

# IMPORTANT: Do note add `set -e` to this file.

wait_for_it() {
    local timeout=$1
    local spacer=2
    shift

    if ! [ $timeout = '-1' ]; then
        local times_to_run=$((timeout / spacer))

        echo "Checking $@, $times_to_run times"
        for i in $(seq $times_to_run); do
          eval $@ && break
          echo .
          sleep $spacer
        done

        eval $@
    else
        while ! eval $@; do
            echo .
            sleep $spacer
        done
    fi
}

delete_image() {
    local image_and_tag=$1

    IFS=':' read -r -a array <<< $image_and_tag
    local image="${array[0]}"
    local tag="${array[1]}"
    
    if gcloud container images list-tags $image | grep $tag; then
        gcloud container images delete --force-delete-tags -q $image_and_tag
    fi
}

function initialize_gke() {
  # setup kubectl
  gcloud auth activate-service-account --key-file $GCLOUD_SERVICE_KEY
  gcloud container clusters get-credentials $GCLOUD_CLUSTER_NAME --zone $GCLOUD_ZONE --project $GCLOUD_PROJECT_NAME
}

function initialize_oc() {
  # setup kubectl, oc and docker
  url=$OPENSHIFT_URL

  if [ -z "$OPENSHIFT_TOKEN" ]; then
    oc login "$url" --username="$OPENSHIFT_USERNAME" --password="$OPENSHIFT_PASSWORD" --insecure-skip-tls-verify=true
  else
    oc login "$url" --token="$OPENSHIFT_TOKEN" --insecure-skip-tls-verify=true
  fi

  docker login -u _ -p "$(oc whoami -t)" "$OPENSHIFT_REGISTRY_URL"
}
