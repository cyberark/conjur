#!/bin/bash -ex

export DEBIFY_IMAGE=$(< DEBIFY_IMAGE)
docker run --rm $DEBIFY_IMAGE config script > docker-debify
chmod +x docker-debify

# Update Gemfile.lock for any unpinned dependencies
docker run --rm \
  -v "$(pwd)":"$(pwd)" \
  --workdir "$(pwd)" \
  cyberark/ubuntu-ruby-builder:latest \
  sh -c "bundle lock --update=conjur-api"

# Create possum deb
./docker-debify package \
  --dockerfile=Dockerfile.fpm \
  --output=deb \
  --version "$(<VERSION)" \
  --image="cyberark/ubuntu-ruby-builder" \
  --image-tag="latest" \
  possum \
  -- \
  --depends tzdata

# Create possum rpm
# The '--rpm-rpmbuild-define' flag is added to avoid packaging build
# files that are not needed and cause conflict with conjur-ui on install
./docker-debify package \
  --dockerfile=Dockerfile.fpm \
  --output=rpm \
  --version "$(<VERSION)" \
  --image="cyberark/ubuntu-ruby-builder" \
  --image-tag="latest" \
  possum \
  -- \
  --depends tzdata \
  --rpm-rpmbuild-define '_build_id_links none'
