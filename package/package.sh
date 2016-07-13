#!/bin/bash -ex

version=$(cat VERSION)-g$(git rev-parse --short HEAD)

debify package \
	-v $version \
	-d $PWD/.. \
	possum \
	-- \
	--depends ruby2.2 \
	--depends libpq5
