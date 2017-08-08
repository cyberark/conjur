#!/bin/bash -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker build -t conjurinc/conjur-apidocs -f $DIR/Dockerfile.apidocs $DIR
