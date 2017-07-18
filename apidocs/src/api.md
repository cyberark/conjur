FORMAT: 1A

# Conjur Community Edition API

This is official documentation of the Conjur Community Edition API. It
allows you tremendous flexibility to control and manipulate your
Conjur software.

# User Authentication

Most API calls require an authentication access token. To obtain an access token as a user:

1. Use a username and password to obtain an API key (refresh token) with the [Authentication > Login](/#TODO) route.
2. Use the API key to obtain an access token with the [Authentication > Authenticate](/#TODO) route.

Access tokens expire after 8 minutes. You need to obtain a new token after it expires.
Token expiration and renewal is handled automatically by the
Conjur [CLI](https://developer.conjur.net/cli) and [client libraries](https://developer.conjur.net/clients).

## SSL verification

Use the public key you obtained when running `conjur init` for SSL verification when talking to your Conjur endpoint.
This is a *public* key, so you can check it into source control if needed.

For example, with curl:

```
$ curl --cacert <certfile> ...
```

## Authenticate [/api/authn/users/{login}/authenticate]

### Exchange a user login and API key for an access token [POST]

Conjur authentication is based on auto-expiring access tokens, which are issued by Conjur when presented with both:

* A login name
* A corresponding password or API key (aka 'refresh token')

The Conjur Access Token provides authentication for API calls.

For API usage, it is ordinarily passed as an HTTP Authorization "Token" header.

```
Authorization: Token token="eyJkYX...Rhb="
```

Before the access token can be used to make subsequent calls to the API, it must be formatted.
Take the response from the this call and base64-encode it, stripping out newlines.

```
token=$(echo -n $response | base64 | tr -d '\r\n')
```

The access token can now be used for Conjur API access.

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

* It is JSON.
* It carries the login name and other data in a payload.
* It is signed by a private authentication key, and verified by a corresponding public key.
* It carries the signature of the public key for easy lookup in a public key database.
* It has a fixed life span of several minutes, after which it is no longer valid.

---

**Request Body**

Description|Required|Type|Example|
-----------|----|--------|-------|
Conjur API key|yes|`String`|"14m9cf91wfsesv1kkhevg12cdywm2wvqy6s8sk53z1ngtazp1t9tykc"|

**Response**

|Code|Description|
|----|-----------|
|200|The response body is the raw data needed to create an access token|
|401|The credentials were not accepted|

+ Parameters
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

# Group Secrets

## Batch Secret Retrieval [/secrets{?variable_id}]

### Batch Secret Retrieval [GET]

Fetch the values of a list of variables.  This operation is more efficient than
fetching the values one by one.

This method will fail unless:
  * All of the variables exist
  * You have permission to `'execute'` all of the variables

+ Parameters
    + variable_id: cucumber:variable:secret1,cucumber:variable:secret2 (array) - Resource IDs of the secrets you wish to retrieve.

+ Response 200 (application/json)

        {
            "cucumber:variable:secret1": "secret_data",
            "cucumber:variable:secret2": "more_secret_data"
        }
