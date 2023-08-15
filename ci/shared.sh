#!/usr/bin/env bash

export REPORT_ROOT=/src/conjur-server

# Sets the number of parallel processes for cucumber tests
# Due to naming conventions for parallel_cucumber this begins at 1 NOT 0
PARALLEL_PROCESSES=${PARALLEL_PROCESSES:-2}

get_parallel_services() {
  # get_parallel_services converts docker service names
  # to the appropriate naming conventions expected for
  # parallel cucumber tests.

  # Args:
  #   $1: A string of space delimited docker service name(s)

  # Returns:
  #  An array of docker service names matching the expected
  #  parallel cucumber naming convention.
  local services
  local parallel_services
  read -ra services <<< "$1"

  for service in "${services[@]}"; do
    for (( i=1; i<=PARALLEL_PROCESSES; i++ )); do
      if (( i == 1 )) ; then
        parallel_services+=("$service")
      else
        parallel_services+=("$service${i}")
      fi
    done
  done

  echo "${parallel_services[@]}"
}

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

  local parallel_services
  read -ra parallel_services <<< "$(get_parallel_services 'conjur pg')"

  if (( ${#services[@]} )); then
    $COMPOSE up --no-deps --no-recreate -d "${parallel_services[@]}" "${services[@]}"
  else
    $COMPOSE up --no-deps --no-recreate -d "${parallel_services[@]}"
  fi

  read -ra parallel_services <<< "$(get_parallel_services 'conjur')"
  for parallel_service in "${parallel_services[@]}"; do
    $COMPOSE exec -T "$parallel_service" conjurctl wait --retries 180
  done

  echo "Create cucumber account..."

  for parallel_service in "${parallel_services[@]}"; do
    $COMPOSE exec -T "$parallel_service" conjurctl account create cucumber
  done

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

  # Generate api key ENV variables based on the
  # number of parallel processes.
  for (( i=1; i <= ${#parallel_services[@]}; ++i )); do
    index=$(( i - 1 ))
    if (( i == 1 )) ; then
        api_keys+=("CONJUR_AUTHN_API_KEY=$(_get_api_key "${parallel_services[$index]}")")
    else
        api_keys+=("CONJUR_AUTHN_API_KEY${i}=$(_get_api_key "${parallel_services[$index]}")")
    fi
  done

  # Generate authn_local socket ENV variables based on the
  # number of parallel processes.
  for (( i=1; i <= ${#parallel_services[@]}; ++i )); do
    if (( i == 1 )) ; then
      sockets+=("AUTHN_LOCAL_SOCKET=/run/authn-local/.socket")
    else
      sockets+=("AUTHN_LOCAL_SOCKET${i}=/run/authn-local${i}/.socket")
    fi
  done

  # Add the cucumber env vars that we always want to send.
  # Note: These are args for docker compose run, and as such the right hand
  # sides of the = do NOT require escaped quotes.  docker compose takes the
  # entire arg, splits on the =, and uses the rhs as the value,
  env_var_flags+=(
    -e "CUCUMBER_NETWORK=$(_find_cucumber_network)"
    -e "INFRAPOOL_CUCUMBER_FILTER_TAGS=$INFRAPOOL_CUCUMBER_FILTER_TAGS"
  )

  # Add parallel process api_keys to the env_var_flags
  for api_key in "${api_keys[@]}"; do
    env_var_flags+=(-e "$api_key")
  done

  # Add parallel process authn_local sockets to the env_var_flags
  for socket in "${sockets[@]}"; do
    env_var_flags+=(-e "$socket")
  done

  # If there's no tty (e.g. we're running as a Jenkins job), pass -T to
  # docker compose.
  run_flags=(--no-deps --rm)
  if ! tty -s; then
    run_flags+=(-T)
  fi

  # THE INFRAPOOL_CUCUMBER_FILTER_TAGS environment variable is not natively
  # implemented in cucumber-ruby, so we pass it as a CLI argument
  # if the variable is set.
  local cucumber_tags_arg
  if [[ -n "$INFRAPOOL_CUCUMBER_FILTER_TAGS" ]]; then
    cucumber_tags_arg="--tags \"$INFRAPOOL_CUCUMBER_FILTER_TAGS\""
  fi

  # Stage 3: Run Cucumber
  # -----------------------------------------------------------

  echo "ENV_ARG_FN: ${env_arg_fn}" >&2
  echo "RUN_FLAGS: ${run_flags[*]}" >&2
  echo "ENV_VAR_FLAGS: ${env_var_flags[*]}" >&2
  echo "CUCUMBER TAGS: ${cucumber_tags_arg}" >&2
  echo "CUCUMBER PROFILE: ${profile}" >&2


  # Have to add tags in profile for parallel to run properly
  # ${cucumber_tags_arg} should overwrite the profile tags in a way for @smoke to work correctly
  $COMPOSE run "${run_flags[@]}" "${env_var_flags[@]}" \
    cucumber -ec "\
      /oauth/keycloak/scripts/fetch_certificate &&
      bundle exec parallel_cucumber . -n ${PARALLEL_PROCESSES} \
       -o '--strict --profile \"${profile}\" ${cucumber_tags_arg} \
       --format json --out \"cucumber/$profile/cucumber_results.json\" \
       --format html --out \"cucumber/$profile/cucumber_results.html\" \
       --format junit --out \"cucumber/$profile/features/reports\"'"

  # Stage 4: Coverage results
  # -----------------------------------------------------------

  # Simplecov writes its report using an at_exit ruby hook. If the container is
  # killed before ruby, the report doesn't get written. So here we kill the
  # process to write the report. The container is kept alive using an infinite
  # sleep in the at_exit hook (see .simplecov).
  for parallel_service in "${parallel_services[@]}"; do
    $COMPOSE exec -T "$parallel_service" bash -c "pkill -f 'puma 6'"
  done
}

_get_api_key() {
  local service=$1

  $COMPOSE exec -T "${service}" conjurctl \
    role retrieve-key cucumber:user:admin | tr -d '\r'
}

_find_cucumber_network() {
  local net

  # docker compose conjur/pg services use the same
  # network for 1 or more instances so only conjur is passed
  # and not other parallel services.
  conjur_id=$($COMPOSE ps -q conjur)
  net=$(docker inspect "${conjur_id}" --format '{{.HostConfig.NetworkMode}}')

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
  local dc_cmd=($COMPOSE exec -T "$svc" "${pg_cmd[@]}")

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
    $COMPOSE exec -T ldap-server bash -c "$ldap_check_cmd" |
    grep '^search: 3$'
  ) >/dev/null 2>&1
}

start_ldap_server() {
  # Start LDAP.
  $COMPOSE up --no-deps --detach ldap-server

  # Wait for up to 90 seconds, since it's slow.
  echo "Ensuring that LDAP is up..."
  if ! timeout_secs=90 wait_for_cmd is_ldap_up; then
    echo 'LDAP server failed to start in time'
    exit 1
  fi

  echo "Done."
}
