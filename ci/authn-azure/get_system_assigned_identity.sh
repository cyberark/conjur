#!/bin/bash -ex

### Retrieves a System Assigned Identity access token from Azure metadata service and
### returns the System Assigned Identity Object ID

main() {
  azure_access_token="$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -H Metadata:true | jq -r '.access_token')"

  decoded_token_payload=$(decode_jwt_payload "$azure_access_token")

  object_id="$(echo "$decoded_token_payload" | jq -r '.oid')"

  echo "$object_id"
}

# Decodes the payload of a given JWT
decode_jwt_payload(){
  decode_jwt_part "$1" 2
}

# Decodes a JWT and returns either the header or the payload
# $1 - the encoded JWT
# $2 - the required part: 1 for header, 2 for payload, 3 for signature
decode_jwt_part(){
  jwt_part_to_decode="$(get_jwt_part "$1" "$2")"

  decoded_jwt_part="$(decode_base64 "$jwt_part_to_decode")"

  echo "$decoded_jwt_part"
}

# Splits a given JWT and returns the required part
# $1 - the encoded JWT
# $2 - the required part: 1 for header, 2 for payload, 3 for signature
get_jwt_part(){
  echo -n $1 | cut -d "." -f $2
}

# Decodes a given data that is base64 encoded
decode_base64() {
  local len=$((${#1} % 4))
  local result="$1"
  if [ $len -eq 2 ]; then result="$1"'=='
  elif [ $len -eq 3 ]; then result="$1"'='
  fi
  echo "$result" | tr '_-' '/+' | openssl enc -d -base64
}

main
