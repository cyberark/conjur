## Add a secret [/secrets/{account}/{kind}/{identifier}]

### Add a secret [POST]

Creates a secret value within the specified Variable. If a secret already exists, the value will be replaced with a new version. The twenty most recent secret versions are retained.

#### Example with `curl`

```
curl -H "$(conjur authn authenticate -H)" \
     --data "don't tell" \
     https://eval.conjur.org/secrets/mycorp/variable/prod-app/db-pass
```

---

**Request Body**

| Description  | Required | Type     | Example                  |
|--------------|----------|----------|--------------------------|
| Secret data  | yes      | `Binary` | 3ab2fabadea7e7b68acc893e |

**Response**

| Code | Description                             |
|------|-----------------------------------------|
|  201 | The secret value was added successfully |
|<!-- include(partials/http_401.md) -->|
|<!-- include(partials/http_403.md) -->|
|<!-- include(partials/http_422.md) -->|

+ Parameters
  + account: mycorp (string) - organization account name.
  + kind: variable (string) - should be "variable".
  + identifier: db-password (string) - id of the variable.

+ Response 201 (application/xml)

## Retrieve a secret [/secrets/{account}/{kind}/{identifier}{?version}]

### Retrieve a secret [GET]

Fetches the value of a secret from the specified Variable. The latest version will be retrieved unless the version parameter is specified. The twenty most recent secret versions are retained.

The secret data is returned in the response body.

#### Example with `curl`

```
curl -H "$(conjur authn authenticate -H)" \
    https://eval.conjur.org/secrets/mycorp/variable/prod-app/db-pass
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
  + account: mycorp (string) - organization account name.
  + kind: variable (string) - should be "variable".
  + identifier: db-password (string) - id of the variable.
  + version: 1 (integer) - the version you want to retrieve (Conjur keeps the last 20 versions of a secret).

+ Response 200 (application/json)

  ```
  don't tell
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
  + variable_ids: cucumber:variable:secret1,cucumber:variable:secret2 (array) - Comma-delimited resource IDs of the variables.

+ Response 200 (application/json)

    ```
    {
        "cucumber:variable:secret1": "secret_data",
        "cucumber:variable:secret2": "more_secret_data"
    }
    ```
