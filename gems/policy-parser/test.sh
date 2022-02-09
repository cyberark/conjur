#!/bin/bash -ex

# : ${RUBY_VERSION=3.0}
#
# # My local RUBY_VERSION is set to ruby-#.#.# so this allows running locally.
# RUBY_VERSION=$(cut -d '-' -f 2 <<< $RUBY_VERSION)

main() {
  build
  run_tests "$@"
}

# internal functions

build() {
  docker-compose build --pull
}

run_tests() {
  docker-compose run test "$@"
}

main "$@"
