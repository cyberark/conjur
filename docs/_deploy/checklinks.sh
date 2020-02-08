#!/bin/sh -e

# Check site for broken links.
# Run this in the root project directory.

docker run \
  -v $PWD/_site:/_site:ro \
  --network none \
  --rm \
  18fgsa/html-proofer \
  --check-external-hash \
  --disable-external \
  --enforce-https \
  --url-ignore '#' \
  /_site

