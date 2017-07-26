## Authenticate [/authn/{account}/{login}/authenticate]

### Exchange a user login and API key for an access token [POST]

Conjur authentication is based on auto-expiring access tokens, which are issued by Conjur when presented with both:

* A login name (eg. latoya)
* A corresponding API key obtained from (Login)[#user-authentication-login-get]

The Conjur Access Token provides authentication for API calls. It is passed as an HTTP Authorization "Token" header like so:

```
Authorization: Token token="eyJkYX...Rhb="
```

Before the access token can be used to make subsequent calls to the API, it must be formatted.
Take the response from the this call and base64-encode it, stripping out newlines.

```
token=$(echo -n $response | base64 | tr -d '\r\n')
```

The access token can now be used for Conjur API access like this:

```
curl --cacert <certfile> \
     -H "Authorization: Token token=\"$token\"" \
     <route>
```

NOTE: If you have the Conjur CLI installed you can get a pre-formatted access token with:

```
conjur authn authenticate -H
```

Properties of the access token include:

* It is JSON
* It carries the login name and other data in a payload
* It is signed by a private authentication key, and verified by a corresponding public key
* It carries the signature of the public key for easy lookup in a public key database
* It has a fixed life span of several minutes, after which it is no longer valid

---

**Request Body**

| Description    | Required | Type     | Example                        |
|----------------|----------|----------|--------------------------------|
| Conjur API key | yes      | `String` | "14m9cf91wfsesv1kkhevg12cdywm" |
| Account        | yes      | `String` | "cyberark"                      |

**Response**

| Code | Description                                                        |
|------|--------------------------------------------------------------------|
|  200 | The response body is the raw data needed to create an access token |
|  401 | The credentials were not accepted                                  |

+ Parameters
    + account: cyberark (string) - organization name
    + login: latoya (string) - login name for the user/host. For hosts this is `host/<hostid>`

+ Request (text/plain)
    + Body

        ```
        14m9cf91wfsesv1kkhevg12cdywm2wvqy6s8sk53z1ngtazp1t9tykc
        ```

+ Response 200

    ```
    {
        "data": "latoya",
        "timestamp": "2017-04-24 20:31:50 UTC",
        "signature": "BpR0FEbQL8TpvpIjJ1awYr8uklvPecmXt-EpIIPcHpdAKBjoyrBQDZv8he1z7vKtF54H3webS0imvL0-UrHOE5yp_KB0fQdeF_z-oPYmaTywTcbwgsHNGzTkomcEUO49zeCmPdJN_zy_umiLqFJMBWfyFGMGj8lcJxcKTDMaXqJq5jK4e2-u1P0pG_AVnat9xtabL2_S7eySE1_2eK0SC7FHQ-7gY2b0YN7L5pjtHrfBMatg3ofCAgAbFmngTKCrtH389g2mmYXfAMillK1ZrndJ-vTIeDg5K8AGAQ7pz8xM0Cb0rqESWpYMc8ZuaipE5UMbmOym57m0uMuMftIJ_akBQZjb4zB-3IBQE25Sb4nrbFCgH_OyaqOt90Cw4397",
        "key": "15ab2712d65e6983cf7107a5350aaac0"
    }
    ```
