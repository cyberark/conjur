#!/usr/bin/env bash

export REPORT_ROOT=/src/conjur-server

# Note: This function is long but purposefully not split up.  None of its parts
# are re-used, and the split-up version is harder to follow and duplicates
# argument processing.
_run_cucumber_tests() {
  local profile
  local services
  local env_arg_fn

  profile="$1"

  if [[ -n "$2" ]]; then
    read -ra services <<< "$2"
  fi

  if [[ -n "$3" ]]; then
    env_arg_fn="$3"
  fi

  # Stage 1: Setup reports, start services, create cuke account
  # -----------------------------------------------------------

  echo "Create report folders..."

  mkdir -p "cucumber/$profile/features/reports"
  rm -rf "cucumber/$profile/features/reports/*"

  echo "Start all services..."

  echo "COMPOSE CMD: docker-compose up --no-deps --no-recreate -d pg conjur pg2 conjur2 ${services[*]}"
  #docker-compose up --no-deps --no-recreate -d pg conjur "${services[@]}"
  if [[ -z "${services[*]}" ]]; then
    docker-compose up --no-deps --no-recreate -d pg conjur pg2 conjur2
  else
    docker-compose up --no-deps --no-recreate -d pg conjur pg2 conjur2 "${services[@]}"
  fi
  #docker-compose up --no-deps --no-recreate -d pg3 conjur3
  docker-compose exec -T conjur conjurctl wait --retries 180
  docker-compose exec -T conjur2 conjurctl wait --retries 180
  #docker-compose exec -T conjur3 conjurctl wait --retries 180

  echo "Create cucumber account..."

  docker-compose exec -T conjur conjurctl account create cucumber
  docker-compose exec -T conjur2 conjurctl account create cucumber
  #docker-compose exec -T conjur3 conjurctl account create cucumber

  echo "Docker PS after:"
  docker-compose ps -a

  docker network ls

  #read -p "Press key to continue.. " -n1 -s
  docker-compose ps -a


  # Stage 2: Prepare cucumber environment args
  # -----------------------------------------------------------

  local env_vars
  local env_var_flags
  local run_flags

  # Hydrate the env args using the env_arg_fn and a nameref.
  env_vars=()
  if [[ -n "$env_arg_fn" ]]; then
    "$env_arg_fn" env_vars
  fi

  # Add the -e flags before each of the var=val items.
  env_var_flags=()
  for item in "${env_vars[@]}"; do
    env_var_flags+=(-e "$item")
  done

  # Add the cucumber env vars that we always want to send.
  # Note: These are args for docker-compose run, and as such the right hand
  # sides of the = do NOT require escaped quotes.  docker-compose takes the
  # entire arg, splits on the =, and uses the rhs as the value,
  env_var_flags+=(
    -e "CONJUR_AUTHN_API_KEY=$(_get_api_key)"
    -e "CONJUR_AUTHN_API_KEY2=$(_get_api_key2)"
  #  -e "CONJUR_AUTHN_API_KEY3=$(_get_api_key3)"
    -e "CUCUMBER_NETWORK=$(_find_cucumber_network)"
    -e "CUCUMBER_FILTER_TAGS=$CUCUMBER_FILTER_TAGS"
  )


  # If there's no tty (e.g. we're running as a Jenkins job), pass -T to
  # docker-compose.
  run_flags=(--no-deps --rm)
  if ! tty -s; then
    run_flags+=(-T)
  fi

  # THE CUCUMBER_FILTER_TAGS environment variable is not natively
  # implemented in cucumber-ruby, so we pass it as a CLI argument
  # if the variable is set.
  local cucumber_tags_arg
  if [[ -n "$CUCUMBER_FILTER_TAGS" ]]; then
    cucumber_tags_arg="--tags \"$CUCUMBER_FILTER_TAGS\""
  fi

  # Stage 3: Run Cucumber
  # -----------------------------------------------------------

  echo "ENV_ARG_FN: ${env_arg_fn}" >&2
  echo "RUN_FLAGS: ${run_flags[*]}" >&2
  echo "ENV_VAR_FLAGS: ${env_var_flags[*]}" >&2
  echo "CUCUMBER TAGS: ${cucumber_tags_arg}" >&2
  echo "CUCUMBER PROFILE: ${profile}" >&2


  docker-compose run "${run_flags[@]}" "${env_var_flags[@]}" \
    cucumber -ec "\
      /oauth/keycloak/scripts/fetch_certificate &&
      bundle exec parallel_test . --type cucumber -n 2 \
       -o '--strict ${cucumber_tags_arg} -p \"${profile}\" \
       --format json --out \"cucumber/$profile/cucumber_results.json\" \
       --format html --out \"cucumber/$profile/cucumber_results.html\" \
       --format junit --out \"cucumber/$profile/features/reports\"'"

      #bundle exec parallel_test cucumber --type cucumber -n 2 \
       #-o '--tags @api -p \"$profile\" \
       #--format json --out \"cucumber/$profile/cucumber_results.json\" \
       #--format html --out \"cucumber/$profile/cucumber_results.html\" \
       #--format junit --out \"cucumber/$profile/features/reports\"'"

      #bundle exec parallel_test . --type cucumber -n 2 \
       #-o '--strict ${cucumber_tags_arg} -p \"${profile}\" \
       #--format json --out \"cucumber/$profile/cucumber_results.json\" \
       #--format html --out \"cucumber/$profile/cucumber_results.html\" \
       #--format junit --out \"cucumber/$profile/features/reports\"'"

      #bundle exec cucumber \
       #--strict \
       #${cucumber_tags_arg} \
       #-p \"$profile\" \
       #--format json --out \"cucumber/$profile/cucumber_results.json\" \
       #--format html --out \"cucumber/$profile/cucumber_results.html\" \
       #--format junit --out \"cucumber/$profile/features/reports\""

  # Stage 4: Coverage results
  # -----------------------------------------------------------

  # Simplecov writes its report using an at_exit ruby hook. If the container is
  # killed before ruby, the report doesn't get written. So here we kill the
  # process to write the report. The container is kept alive using an infinite
  # sleep in the at_exit hook (see .simplecov).
  docker-compose exec -T conjur bash -c "pkill -f 'puma 5'"
  docker-compose exec -T conjur2 bash -c "pkill -f 'puma 5'"
  #docker-compose exec -T conjur3 bash -c "pkill -f 'puma 5'"
}

_get_api_key() {
  docker-compose exec -T conjur conjurctl \
    role retrieve-key cucumber:user:admin | tr -d '\r'
}

_get_api_key2() {
  docker-compose exec -T conjur2 conjurctl \
    role retrieve-key cucumber:user:admin | tr -d '\r'
}

_get_api_key3() {
  docker-compose exec -T conjur3 conjurctl \
    role retrieve-key cucumber:user:admin | tr -d '\r'
}

_find_cucumber_network() {
  local net

  # Docker compose conjur/pg services use the same network for 1 or more instances
  conjur_id=$(docker-compose ps -q conjur)
  net=$(docker inspect "${conjur_id}" --format '{{.HostConfig.NetworkMode}}')

  #read -p "Press key to continue.. " -n1 -s
  docker network inspect "$net" \
    --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}'
}


# Retry given cmd every second until success or timeout.
#
# Args:
#   - timeout_secs: Given as an env var.
#   - All remaining args make up the command to test, beginning with the cmd
#     name, and including any flags and arguments to that command.
wait_for_cmd() {
  : "${timeout_secs:=120}"
  local cmd=("$@")

  for _ in $(seq "$timeout_secs"); do
    if "${cmd[@]}"; then
      return 0
    fi
    sleep 1
  done

  return 1
}

_wait_for_pg() {
  local svc=$1
  local pg_cmd=(psql -U postgres -c "select 1" -d postgres)
  local dc_cmd=(docker-compose exec -T "$svc" "${pg_cmd[@]}")

  echo "Waiting for pg to come up..."

  if ! timeout_secs=120 wait_for_cmd "${dc_cmd[@]}"; then
    echo "ERROR: pg service '$svc' failed to come up."
    exit 1
  fi

  echo "Done."
}

is_ldap_up() {
  local ldap_check_cmd="ldapsearch -x -ZZ -H ldapi:/// -b dc=conjur,dc=net \
    -D \"cn=admin,dc=conjur,dc=net\" -w ldapsecret"

  # Note: We need the subshell to group the commands.
  (
    set -o pipefail
    docker-compose exec -T ldap-server bash -c "$ldap_check_cmd" |
    grep '^search: 3$'
  ) >/dev/null 2>&1
}

start_ldap_server() {
  # Start LDAP.
  docker-compose up --no-deps --detach ldap-server

  # Wait for up to 90 seconds, since it's slow.
  echo "Ensuring that LDAP is up..."
  if ! timeout_secs=90 wait_for_cmd is_ldap_up; then
    echo 'LDAP server failed to start in time'
    exit 1
  fi
  echo "Done."
}
