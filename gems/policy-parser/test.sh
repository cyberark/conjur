#!/bin/bash -ex

# : ${RUBY_VERSION=3.0}
#
# # My local RUBY_VERSION is set to ruby-#.#.# so this allows running locally.
# RUBY_VERSION=$(cut -d '-' -f 2 <<< $RUBY_VERSION)

# Create a value to determine if the runtime container
# for Jenkins can run Compose v2 syntax
COMPOSE="docker compose"
if grep -m 1 'Red Hat' /etc/os-release; then
  COMPOSE="docker-compose"
fi
export COMPOSE

main() {
  build
  run_tests "$@"
}

# internal functions

build() {
  $COMPOSE build --pull
}

run_tests() {
  $COMPOSE run test "$@"
}

main "$@"
