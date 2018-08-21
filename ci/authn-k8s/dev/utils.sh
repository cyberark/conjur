#!/usr/bin/env bash

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
