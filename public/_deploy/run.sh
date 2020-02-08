#!/bin/sh -e

# Run this script in the project root to launch a local, (mostly) live-updated copy of the website.

docker build . -t conjur-oss

# create mount points for temporary and build files
mkdir -p .sass-cache _site

docker run \
  -v $PWD:/srv/jekyll:ro \
  -v /srv/jekyll/.sass-cache \
  -v /srv/jekyll/_site \
  --rm \
  -p 4000:4000 \
  conjur-oss \
  jekyll serve
