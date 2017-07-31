## Authenticate [/authn/{account}/{login}/authenticate]

### Authenticate [POST]

Gets a [short-lived access token](/reference/cryptography.html#authentication-tokens), which can be used to authenticate requests to (most of) the rest of the Conjur API. A client can obtain an access token by presenting a valid login name and API key.

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
    + account: mycorp (string) - organization name
    + login: alice (string) - Login name of the client. For users, it's the user id. For hosts, the login name is `host/<host-id>`

+ Request (text/plain)
    + Body

        ```
        14m9cf91wfsesv1kkhevg12cdywm2wvqy6s8sk53z1ngtazp1t9tykc
        ```

+ Response 200

    ```
    {
        "data": "alice",
        "timestamp": "2017-04-24 20:31:50 UTC",
        "signature": "BpR0FEbQL8TpvpIjJ1awYr8uklvPecmXt-EpIIPcHpdAKBjoyrBQDZv8he1z7vKtF54H3webS0imvL0-UrHOE5yp_KB0fQdeF_z-oPYmaTywTcbwgsHNGzTkomcEUO49zeCmPdJN_zy_umiLqFJMBWfyFGMGj8lcJxcKTDMaXqJq5jK4e2-u1P0pG_AVnat9xtabL2_S7eySE1_2eK0SC7FHQ-7gY2b0YN7L5pjtHrfBMatg3ofCAgAbFmngTKCrtH389g2mmYXfAMillK1ZrndJ-vTIeDg5K8AGAQ7pz8xM0Cb0rqESWpYMc8ZuaipE5UMbmOym57m0uMuMftIJ_akBQZjb4zB-3IBQE25Sb4nrbFCgH_OyaqOt90Cw4397",
        "key": "15ab2712d65e6983cf7107a5350aaac0"
    }
    ```
