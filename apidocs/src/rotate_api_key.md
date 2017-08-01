## Rotate an API key [/authn/{account}/api_key]

Replaces the API key of a role with a new, securely random 
API key. The new API key is returned as the response body.

### Rotate your own API key [PUT /authn/{account}/api_key]

**Permissions required**:

Any authenticated role can rotate its own API key. Basic authorization (username plus password or API key) must be provided.

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
  + account: <!-- include(partials/account_param.md) -->

+ Request
    + Headers
    
        ```
        Authorization: Basic ZGFuaWVsOjlwOG5mc2RhZmJw
        ```
        
+ Response 200 (text/html; charset=utf-8)

    ```
    14m9cf91wfsesv1kkhevg12cdywm2wvqy6s8sk53z1ngtazp1t9tykc
    ```

### Rotate another role's API key [PUT /authn/{account}/api_key{?id}]

Rotates the API key of a role which is not the current authenticated client.

**Permissions required**: `update` privilege on the role whose API key is being rotated.

---

<!-- include(partials/auth_header_table.md) -->

**Response**

|Code|Description                     |
|----|--------------------------------|
|200 |The response body is the API key|
|<!-- include(partials/http_401.md) -->|
|<!-- include(partials/http_403.md) -->|

---

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + id: bob (string, optional) - Id of the user to rotate.

+ Request
    <!-- include(partials/auth_header_code.md) -->

+ Response 200 (text/html; charset=utf-8)

    ```
    14m9cf91wfsesv1kkhevg12cdywm2wvqy6s8sk53z1ngtazp1t9tykc
    ```
