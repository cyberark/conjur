#!/usr/bin/env bash
set -euo pipefail


IMAGE="registry.tld/conjur-appliance:eval-authn-k8s-label-selector"

echo "FROM registry.tld/conjur-appliance:5.0-stable

# Copy new source files
$(
    echo "
app/domain/authentication/authn_k8s/authentication_request.rb
app/domain/authentication/authn_k8s/consts.rb
app/domain/authentication/authn_k8s/k8s_object_lookup.rb
app/domain/authentication/authn_k8s/k8s_resource_validator.rb
app/domain/authentication/constraints/required_exclusive_constraint.rb
app/domain/errors.rb
" |  docker run --rm -i --entrypoint="" ruby:2-alpine ruby -e '
files = STDIN.read.split("\n").reject(&:empty?)
puts files.map {|file| "COPY #{file} /opt/conjur/possum/#{file}"}.join("\n")
'
)

RUN chown -R conjur:conjur /opt/conjur/possum/app" > Dockerfile.appliance

docker build -f ./Dockerfile.appliance -t "${IMAGE}" .
docker push "${IMAGE}"
