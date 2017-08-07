#!/bin/bash -ex

run_dev=true

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -j|--jenkins)
    run_dev=false
    ;;
    *)
    ;;
esac
shift # past argument or value
done

docker build -t conjur .

docker build -t conjur-test -f Dockerfile.test .

if [[ $run_dev = true ]]; then
  docker build -t conjur-dev -f Dockerfile.dev .
fi

docker tag conjur conjurinc/conjur || docker tag -f conjur conjurinc/conjur
