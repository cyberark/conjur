#!/bin/bash -e

function finish {
  echo 'Removing test environment'
  echo '---'
  docker-compose down --rmi 'local' --volumes
}

trap finish EXIT

function main() {
  # Generate reports folders locally
  mkdir -p spec/reports features/reports features_v4/reports

  startConjur
  runTests_5
  runTests_4
}

function startConjur() {
  echo 'Starting Conjur environment'
  echo '-----'
  docker-compose pull
  docker-compose build
  docker-compose up -d pg conjur_4 conjur_5
}

function runTests_5() {
  echo 'Waiting for Conjur v5 to come up, and configuring it...'
  ./ci/configure_v5.sh

  local api_key=$(docker-compose exec -T conjur_5 rake 'role:retrieve-key[cucumber:user:admin]')

  echo 'Running tests'
  echo '-----'
  docker-compose run --rm \
    -e CONJUR_AUTHN_API_KEY="$api_key" \
    tester_5 rake jenkins_init jenkins_spec jenkins_cucumber_v5
}

function runTests_4() {
  echo 'Waiting for Conjur v4 to come up, and configuring it...'
  ./ci/configure_v4.sh

  local api_key=$(docker-compose exec -T conjur_4 su conjur -c "conjur-plugin-service authn env RAILS_ENV=appliance rails r \"puts User['admin'].api_key\" 2>/dev/null")

  echo 'Running tests'
  echo '-----'
  docker-compose run --rm \
    -e CONJUR_AUTHN_API_KEY="$api_key" \
    tester_4 rake jenkins_cucumber_v4
}

main
