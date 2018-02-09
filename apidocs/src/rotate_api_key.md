## Rotate an API key [/authn/{account}/api_key]

Replaces the API key of a role with a new, securely random API key. The new API
key is returned as the response body.

### Rotate your own API key [PUT /authn/{account}/api_key]

Any role can rotate its own API key. The name and password or current API
key of the role must be provided via [HTTP Basic Authorization][auth].

<!-- include(partials/basic_auth.md) -->

Note that the body of the request must be the empty string.

#### Example with `curl`

Suppose your account is "myorg", you are the user "alice", your password is
"beep-boop", and you want to rotate your API key.

```bash
curl --request PUT --data "" \
     --user alice:beep-boop \
     https://eval.conjur.org/authn/myorg/api_key
```

---

**Headers**

|Field        |Description    |Example                       |
|-------------|---------------|------------------------------|
|Authorization|HTTP Basic Auth|Basic ZGFuaWVsOjlwOG5mc2RhZmJw|

**Response**

|Code|Description                                 |
|----|--------------------------------------------|
|200 |The response body is the API key            |
|<!-- include(partials/http_401.md) -->|

+ Parameters
  + <!-- include(partials/account_param.md) -->

+ Request
    + Headers

        ```
        Authorization: Basic ZGFuaWVsOjlwOG5mc2RhZmJw
        ```

+ Response 200 (text/html; charset=utf-8)

    ```
    14m9cf91wfsesv1kkhevg12cdywm2wvqy6s8sk53z1ngtazp1t9tykc
    ```

### Rotate another role's API key [PUT /authn/{account}/api_key?role={kind}:{identifier}]

Rotates the API key of another role you can update.

Note that the body of the request must be the empty string.

<!-- include(partials/url_encoding.md) -->

<!-- include(partials/role_kinds.md) -->

**Permissions required**

`update` privilege on the role whose API key is being rotated.

#### Example with `curl`

Suppose your account is "myorg" and you want to rotate the API key for user
"alice" whose current password is "beep-boop":

```bash
curl --request PUT --data "" \
     -H "$(conjur authn authenticate -H)" \
     https://eval.conjur.org/authn/myorg/api_key?role=user:alice
```

---

**Headers**

|Field        |Description    |Example                       |
|-------------|---------------|------------------------------|
|Authorization|HTTP Basic Auth|Basic ZGFuaWVsOjlwOG5mc2RhZmJw|

**Response**

|Code|Description                                 |
|----|--------------------------------------------|
|200 |The response body is the API key            |
|401 | The credentials were not accepted          |

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + kind: user (string) - the kind of the role whose API key we will rotate,
    usually "user" or "host"
  + identifier: alice - the id of the role

+ Request
    + Headers

        ```
        Authorization: Basic ZGFuaWVsOjlwOG5mc2RhZmJw
        ```

+ Response 200 (text/html; charset=utf-8)

    ```
    14m9cf91wfsesv1kkhevg12cdywm2wvqy6s8sk53z1ngtazp1t9tykc
    ```
