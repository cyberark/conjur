#!/bin/bash -ex

docker build -t possum .

docker build -t possum-test -f Dockerfile.test .

docker build -t possum-dev -f Dockerfile.dev .

docker tag possum conjurinc/possum || docker tag -f possum conjurinc/possum

