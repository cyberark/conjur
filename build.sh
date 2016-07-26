#!/bin/bash -ex

docker build -t possum .

docker build -t possum-dev -f Dockerfile.dev .

docker tag -f possum conjurinc/possum
