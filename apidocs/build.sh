#!/bin/bash -ex

docker build -t conjurinc/possum-apidocs -f apidocs/Dockerfile.apidocs apidocs
