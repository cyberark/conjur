#!/bin/bash -ex

docker build -t conjur .

docker build -t conjur-test -f Dockerfile.test .

docker build -t conjur-dev -f Dockerfile.dev .

docker tag conjur conjurinc/conjur || docker tag -f conjur conjurinc/conjur
