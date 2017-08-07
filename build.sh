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

docker build -t possum .

docker build -t possum-test -f Dockerfile.test .

docker build -t conjur-dev -f Dockerfile.dev .

if [[ $run_dev = true ]]; then
  docker build -t conjur-dev -f Dockerfile.dev .
fi

docker tag possum conjurinc/possum || docker tag -f possum conjurinc/possum
