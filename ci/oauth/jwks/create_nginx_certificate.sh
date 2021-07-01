#!/bin/bash -ex

TLS_CONF_PATH="/tmp/tls.conf"
SERVER_HEALTH_CHECK_URL="https://jwks"
SERVER_IS_READY="N0"

function input_validation() {
  if [[ ! -f "${TLS_CONF_PATH}" ]]; then
    echo "Error: file is missing ${TLS_CONF_PATH}"
    exit 1
  fi
}

function create_certificate() {
  openssl req -newkey rsa:2048 -days "365" -nodes -x509 -config /tmp/tls.conf -extensions \
     v3_ca -keyout /etc/nginx/nginx.key -out /etc/nginx/nginx.crt
}

function start_nginx() {
  /etc/init.d/nginx start
}

function wait_for_nginx() {
  for i in {1..40}; do
    sleep=5
    set_server_readiness

    if [[ "${SERVER_IS_READY}" == "YES" ]] ; then
      echo "Nginx server is up and ready"
      return 0
    fi

    echo "Nginx not ready yet sleep number $i for $sleep seconds"
    sleep "$sleep"
  done

  echo "Error with Nginx server start or it is too slow"
  exit 1
}

function set_server_readiness()
{
  curl -k --silent --output /dev/null "${SERVER_HEALTH_CHECK_URL}"
  local ret_code=$?
  echo "Return code of accessing ${SERVER_HEALTH_CHECK_URL} is: ${ret_code}"
  if [[ "${ret_code}" -eq 0 ]] ; then
    SERVER_IS_READY="YES"
  fi
}

function main() {
  input_validation
  create_certificate
  start_nginx
  wait_for_nginx
}

main
