## Add a secret [/secrets/{account}/{kind}/{identifier}]

### Add a secret [POST]

Creates a secret value within the specified Variable. 

#### Example with `curl`

```
curl -H "$(conjur authn authenticate -H)" \
     --data "c3c60d3f266074" \
     https://eval.conjur.org/secrets/mycorp/variable/prod/db/password
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

## Retrieve a secret [/secrets/{account}/{kind}/{identifier}{?version}]

### Retrieve a secret [GET]

Fetches the value of a secret from the specified Variable. The latest version will be retrieved unless the version parameter is specified. The twenty most recent secret versions are retained.

The secret data is returned in the response body.

#### Example with `curl`

```
curl -H "$(conjur authn authenticate -H)" \
    https://eval.conjur.org/secrets/mycorp/variable/prod/db/password
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

## Batch retrieval [/secrets{?variable_ids}]

### Batch retrieval [GET]

Fetches multiple secret values in one invocation. It's faster to fetch secrets in batches than to fetch them one at a time.

**Response**

| Code | Description                                                      |
|------|------------------------------------------------------------------|
|  200 | All secret values were retrieved successfully                    |
|<!-- include(partials/http_401.md) -->|
|<!-- include(partials/http_403.md) -->|
|  404 | At least one variable does not exist, or at least one variable does not have any secret values   |
|<!-- include(partials/http_422.md) -->|

+ Parameters
  + variable_ids: mycorp:variable:secret1,mycorp:variable:secret1 (array) - Comma-delimited resource IDs of the variables.

+ Response 200 (application/json)

    ```
    {
        "mycorp:variable:secret1": "c3c60d3f266074",
        "mycorp:variable:secret2": "d8dc3565123941"
    }
    ```
