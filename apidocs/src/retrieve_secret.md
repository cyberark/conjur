## Retrieve a secret [/secrets/{account}/{kind}/{identifier}{?version}]

### Retrieve a secret [GET]

Fetches the value of a secret from the specified Variable. The latest version will be retrieved unless the version parameter is specified. The twenty most recent secret versions are retained.

The secret data is returned in the response body.

Note: Conjur will allow you to add a secret to any resource, but the best practice is to store and retrieve secret data only using Variable resources.

<!-- include(partials/url_encoding.md) -->

#### Example with `curl`

```
curl -H "$(conjur authn authenticate -H)" \
    https://eval.conjur.org/secrets/myorg/variable/prod/db/password
```

---

**Response**

| Code | Description                                                  |
|------|--------------------------------------------------------------|
|  200 | The secret values was retrieved successfully                 |
|<!-- include(partials/http_401.md) -->|
|<!-- include(partials/http_403.md) -->|
|  404 | The variable does not exist, or it does not have any secret values |
|<!-- include(partials/http_422.md) -->|

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + kind: variable (string) - should be "variable"
  + identifier: db/password (string) - id of the variable
  + version: 1 (integer, optional) - version you want to retrieve (Conjur keeps the last 20 versions of a secret)

+ Response 200 (application/json)

  ```
  c3c60d3f266074
  ```
