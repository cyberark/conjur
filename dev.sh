#!/bin/bash -ex

docker build -t conjur-pages-dev .
docker run --rm -it -v $PWD:/opt/conjur -p 4000:4000 conjur-pages-dev bash
