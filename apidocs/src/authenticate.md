## Authenticate [/authn/{account}/{login}/authenticate]

### Authenticate [POST]

Gets a [short-lived access token](https://docs.conjur.org/Latest/en/Content/Get%20Started/cryptography.html?Highlight=cryptography#Authenticationtokens), which can be used to authenticate requests to (most of) the rest of the Conjur API. A client can obtain an access token by presenting a valid login name and API key.

The login must be [URL encoded][percent-encoding]. For example, `alice@devops`
must be encoded as `alice%40devops`.

For host authentication, the login is the host ID with the prefix `host/`. For example, the host `webserver` would login as `host/webserver`, and would be encoded as `host%2Fwebserver`.

[percent-encoding]: https://developer.mozilla.org/en-US/docs/Glossary/percent-encoding

For API usage, the access token is ordinarily passed as an HTTP Authorization "Token" header.

```
Authorization: Token token="eyJkYX...Rhb="
```

Therefore, before the access token can be used to make subsequent calls to the API, a raw token must be formatted.
Take the response from this method and base64-encode it, stripping out newlines. 

```
token=$(echo -n $response | base64 | tr -d '\r\n')
```

The access token can now be used for Conjur API access like this:

```
curl --cacert <certfile> \
     -H "Authorization: Token token=\"$token\"" \
     <url>
```

NOTE: If you have the Conjur CLI installed you can get a pre-formatted access token with:

```
conjur authn authenticate -H
```


---

**Request Body**

The request body is the API key. For example: `14m9cf91wfsesv1kkhevg12cdywm`. 

**Response**

| Code | Description                           |
|------|---------------------------------------|
|  200 | The response body is the access token |
|<!-- include(partials/http_401.md) -->|

+ Parameters
    + <!-- include(partials/account_param.md) -->
    + login: alice (string) - Login name of the client. For users, it's the user id. For hosts, the login name is `host/<host-id>`

+ Request (text/plain)
    + Body

        ```
        14m9cf91wfsesv1kkhevg12cdywm2wvqy6s8sk53z1ngtazp1t9tykc
        ```

+ Response 200

    ```
    {"protected":"eyJhbGciOiJjb25qdXIub3JnL3Nsb3NpbG8vdjIiLCJraWQiOiI0NGIwMjBmNjY0MDBmNzFhZDQ3Y2I0N2IzYTFiNmU5MSJ9","payload":"eyJzdWIiOiJhbGljZSIsImlhdCI6MTUwNTgzMDY1MX0=","signature":"iRLTwNomb_b6TS4e539IIC-isPsc0kIn-F_ajlvnGdrN6brEEHnVha2vm0oDwOjpnmpFrMYLzn8aPo4_7DP3edssfQbpMG6OZI2Ea9DRfkhQGtSQ2fQvhDos_f16EX_jWQkYlsY6T_RurAxf_7VC4hEhjZA8nLkXOohA1DheyoJiT2-7vdpLmf42G7r1gPWHd_JuFkee28Ax2vCi35l4yQXkAHFaLkb3cAD2iwYuavv3qcFnYsT5WhLQqndPoNzgNa4dMvWRkVNUoVmvL30oE6lAlWPO4rFbPpmLwJRJFudDF8IVV9cVRKnV3z79_3RfEsHJ6YTHVX4Cv--cXmkT17QSFp87DK94DAOX3jKvJNo49DdqkzXqAPUIj3CD3IWI"}
    ```
