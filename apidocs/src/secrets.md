## Add Secret Value To Variable [/secrets/{account}/{kind}/{identifier}]

### Add Secret Value [POST]

Creates a secret value within the specified variable. If a secret already exists, the value will be replaced with a new version. The twenty most recent secret versions are retained.

#### Example with `curl`

```
curl -H "$(conjur authn authenticate -H)" \
     --data "don't tell" \
     https://eval.conjur.org/secrets/cyberark/variable/prod-app/db-pass
```

---

**Request Body**

| Description  | Required | Type     | Example                    |
|--------------|----------|----------|----------------------------|
| Secret Value | yes      | `Binary` | "3ab2fabadea7e7b68acc893e" |

**Response**

| Code | Description                             |
|------|-----------------------------------------|
|  201 | The secret value was added successfully |
|      |                                         |

+ Parameters
  + account: cyberark (string) - organization name
  + kind: variable (string) - kind of resource (usually "variable")
  + identifier: db-password (string) - id of the resource as defined in the policy

+ Response 201 (application/xml)

## Retrieve Secret Value [/secrets/{account}/{kind}/{identifier}{?version}]

### Retrieve Secret Value [GET]

Fetch the value of a secret in the specified variable. The latest version will be retrieved unless the version parameter is specified. The twenty most recent secret versions are retained.

#### Example with `curl`

```
curl -H "$(conjur authn authenticate -H)" \
    https://eval.conjur.org/secrets/cyberark/variable/prod-app/db-pass
```

---

**Response**

| Code | Description                                               |
|------|-----------------------------------------------------------|
|  200 | The secret values was retrieved successfully              |
|  401 | The user is not logged in                                 |
|  403 | The user did not have 'execute' privilege on the secret   |
|  404 | The secret does not exist or does not have a stored value |
|  422 | The version parameter was invalid                         |

Supposing the secret's value is "don't tell":

+ Parameters
  + account: cyberark (string) - organization name
  + kind: variable (string) - kind of resource (usually "variable")
  + identifier: db-password (string) - id of the resource as defined in the policy
  + version: 1 (integer) - the version you want to retrieve (Conjur keeps the last 20 versions of a secret)

+ Response 200 (application/json)

  ```
  don't tell
  ```

## Batch Retrieval [/secrets{?variable_id}]

### Batch Secret Retrieval [GET]

Fetch the values of a list of variables. This operation is more efficient than
fetching the values one by one.

**Response**

| Code | Description                                                      |
|------|------------------------------------------------------------------|
|  200 | All secret values were retrieved successfully                    |
|  401 | The user is not logged in                                        |
|  403 | The user did not have 'execute' privilege on one or more secrets |
|  404 | One or more secrets do not exist or do not have a stored value   |
|  422 | variable_id parameter is missing or invalid                      |

+ Parameters
  + variable_id: cucumber:variable:secret1,cucumber:variable:secret2 (array) - Resource IDs of the variables containing the secrets you wish to retrieve.

+ Response 200 (application/json)

    ```
    {
        "cucumber:variable:secret1": "secret_data",
        "cucumber:variable:secret2": "more_secret_data"
    }
    ```
