#!/bin/bash -ex

docker build -t possum-pages-dev .
docker run --rm -it -v $PWD:/opt/possum -p 4000:4000 possum-pages-dev bash
