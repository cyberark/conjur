#!/bin/bash -ex

(cd ..; docker build -t possum-web -f docs/Dockerfile .)

docker run --rm -it -v $PWD/..:/opt/conjur -p 4000:4000 possum-web ${@-jekyll serve -H 0.0.0.0 --source docs}
