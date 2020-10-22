#!/bin/bash -e

# Invokes the function once to test if the function is accessible.
echo "validate_gcf_url_accessible"
gcp_func_url=$1
audience=$2
optional_identity_token=$3

status_code=$(curl -o /dev/null -s -w "%{http_code}\n" \
  -H "Authorization: bearer $optional_identity_token" \
  -H 'Metadata-Flavor: Google' "$gcp_func_url?audience=${audience}")

if [ ! "$status_code" = "200" ]; then
  echo "-- Function returned error, HTTP Status: '${status_code}', \
  cannot obtain token from URL: $gcp_func_url?audience=${audience}"
  exit 1
fi

echo "-> validate_gcf_url_accessible done"
