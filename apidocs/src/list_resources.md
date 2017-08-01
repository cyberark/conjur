## List resources [/resources]

### List resources [GET /resources/{account}{?kind}]

Lists resources within an organization account.

<!-- include(partials/resource_kinds.md) -->

---

<!-- include(partials/auth_header_table.md) -->

**Response**

| Code | Description                       |
|------|-----------------------------------|
|  200 | Resources returned as a JSON list |
|<!-- include(partials/http_401.md) -->|

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + kind: variable (string, optional) - kind of object to list

+ Request
  <!-- include(partials/auth_header_code.md) -->

+ Response 200 (application/json)

    ```
    [
      {
        "created_at": "2017-07-25T06:30:38.768+00:00",
        "id": "mycorp:variable:app-prod/db-password",
        "owner": "mycorp:policy:app-prod",
        "policy": "mycorp:policy:root",
        "permissions": [],
        "annotations": [],
        "secrets": [
          {
            "version": 1
          }
        ]
      },
      {
        "created_at": "2017-07-25T06:30:38.768+00:00",
        "id": "mycorp:policy:app-prod",
        "owner": "mycorp:user:admin",
        "policy": "mycorp:policy:root",
        "permissions": [],
        "annotations": [],
        "policy_versions": []
      }
    ]
    ```

