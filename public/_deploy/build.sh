#!/bin/sh -e

# Build site with jekyll and copy it into _site
#
# Run this in the root project directory.


# These temporary tags should be unique between builds, so use a timestamp
# for human convenience and tack on something random so it doesn't break
# even if parallel builds start on the same second.
TAG=`date -u +%Y%m%d%H%M%S``cat /dev/urandom | tr -dc a-z | head -c5`

IID=conjur-oss:$TAG
CID=conjur-oss-$TAG

set -x

docker build . -t $IID

# create mount points for temporary and build files
mkdir -p .sass-cache _site

docker run \
  -v $PWD:/srv/jekyll:ro \
  -v /srv/jekyll/.sass-cache \
  -v /srv/jekyll/_site \
  --network none \
  --name $CID \
  $IID \
  jekyll build

docker cp $CID:/srv/jekyll/_site .

docker rm $CID

# this is so rmi doesn't remove the actual image and it stays in cache
docker tag $IID conjur-oss:latest

docker rmi $IID
