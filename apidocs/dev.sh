#!/bin/bash -ex

source build.sh

docker run \
        -it \
        --rm \
        -v $PWD/:/apidocs \
        -p 4000:4000 \
        -w /apidocs \
        --name possum-apidocs \
        conjurinc/possum-apidocs \
        sh -c "/home/node/node_modules/.bin/aglio -i src/api.md -s -h 0.0.0.0 -p 4000"
