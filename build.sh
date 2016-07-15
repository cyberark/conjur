#!/bin/bash -ex

docker build -t possum .

docker build -t possum-dev -f Dockerfile.dev .

