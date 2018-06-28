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
