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
