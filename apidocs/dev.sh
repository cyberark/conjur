#!/bin/bash -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source build.sh

docker run \
        -it \
        --rm \
        -v $DIR/src:/home/node/src \
        -v $DIR/templates:/home/node/templates \
        -p 3000:3000 \
        --name possum-apidocs \
        conjurinc/possum-apidocs \
        -w
