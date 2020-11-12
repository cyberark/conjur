#!/bin/bash -ex

### Retrieves a System Assigned Identity access token from Azure metadata service and
### returns the System Assigned Identity Object ID

source "ci/jwt/decode_token.sh"

azure_access_token="$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -H Metadata:true | jq -r '.access_token')"

decoded_token_payload=$(decode_jwt_payload "$azure_access_token")

object_id="$(echo "$decoded_token_payload" | jq -r '.oid')"

echo "$object_id"
