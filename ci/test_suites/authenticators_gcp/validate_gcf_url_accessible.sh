#!/bin/bash -e

# Invokes the function once to test if the function is accessible.
echo "validate_gcf_url_accessible"
gcp_func_url=$1
audience=$2
optional_identity_token=$3

status_code=$(
  curl \
    --output /dev/null \
    --silent \
    --location \
    --write-out "%{http_code}\n" \
    --header "Authorization: bearer $optional_identity_token" \
    --header 'Metadata-Flavor: Google' \
    "$gcp_func_url?audience=${audience}"
  )

if [ ! "$status_code" = "200" ]; then
  echo "-- Function returned error, HTTP Status: '${status_code}', \
  cannot obtain token from URL: $gcp_func_url?audience=${audience}"
  exit 1
fi

echo "-> validate_gcf_url_accessible done"
