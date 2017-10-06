## Login [/authn/{account}/login]

### Login [GET]

Gets the API key of a user given the username and password
via [HTTP Basic Authentication][auth].

Passwords are stored in the Conjur database using bcrypt with a work factor
of 12. Therefore, `login` is a fairly expensive operation. However, once the API
key is obtained, it may be used to inexpensively obtain access tokens by calling
the [Authenticate](#authentication-authenticate-post) method. An access token is
required to use most other parts of the Conjur API.

<!-- include(partials/basic_auth.md) -->

Note that machine roles (Hosts) do not have passwords and do not need to login.

#### Example with `curl`

Suppose your account is "myorg" and you want to get the API key for user
"alice" whose password is "beep-boop":

```bash
curl --user alice:beep-boop \
     https://eval.conjur.org/authn/myorg/login
```

---

**Headers**

| Field         | Description     | Example                |
|---------------|-----------------|------------------------|
| Authorization | HTTP Basic Auth | Basic YWxpY2U6c2VjcmV0 |

**Response**

| Code | Description                       |
|------|-----------------------------------|
|  200 | The response body is the API key  |
|  401 | The credentials were not accepted |

+ Parameters
  + <!-- include(partials/account_param.md) -->

+ Request
    + Headers
    
        ```
        Authorization: Basic YWxpY2U6c2VjcmV0
        ```
        
+ Response 200 (text/html; charset=utf-8)

    ```
    14m9cf91wfsesv1kkhevg12cdywm2wvqy6s8sk53z1ngtazp1t9tykc
    ```
