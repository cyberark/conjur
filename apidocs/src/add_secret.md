## Add a secret [/secrets/{account}/{kind}/{identifier}]

### Add a secret [POST]

Creates a secret value within the specified Variable.

Note: Conjur will allow you to add a secret to any resource, but the best practice is to store and retrieve secret data only using Variable resources.

<!-- include(partials/url_encoding.md) -->

#### Example with `curl`

```
curl -H "$(conjur authn authenticate -H)" \
     --data "c3c60d3f266074" \
     https://eval.conjur.org/secrets/myorg/variable/prod/db/password
```

---

**Request Body**

| Description  | Required | Type     | Example                  |
|--------------|----------|----------|--------------------------|
| Secret data  | yes      | `Binary` | c3c60d3f266074 |

**Response**

| Code | Description                             |
|------|-----------------------------------------|
|  201 | The secret value was added successfully |
|<!-- include(partials/http_401.md) -->|
|<!-- include(partials/http_403.md) -->|
|<!-- include(partials/http_422.md) -->|

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + kind: variable (string) - should be "variable"
  + identifier: db/password (string) - id of the variable

+ Response 201 (application/xml)
