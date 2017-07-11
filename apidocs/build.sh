#!/bin/bash -ex

docker build -t possum-apidocs -f apidocs/Dockerfile.apidocs apidocs

docker tag possum-apidocs conjurinc/possum-apidocs || docker tag -f possum-apidocs conjurinc/possum-apidocs
