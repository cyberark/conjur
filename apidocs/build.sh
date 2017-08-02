#!/bin/bash -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker build -t conjurinc/possum-apidocs -f $DIR/Dockerfile.apidocs $DIR
