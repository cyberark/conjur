## Show a resource [/resources/{account}/{kind}/{identifier}]

### Show a resource [GET /resources/{account}/{kind}/{identifier}]

The response to this method is a JSON document describing a single resource.

**Permissions Required**: `read` permission on the resource.

<!-- include(partials/resource_kinds.md) -->

#### Example using `curl` and `jq`

```
curl -H "$(conjur authn authenticate -H)" \
    https://eval.conjur.org/resources/mycorp/policy/app-prod \
    | jq .
```

---

<!-- include(partials/auth_header_table.md) -->

**Response**

| Code | Description                                         |
|------|-----------------------------------------------------|
|  200 | Role memberships returned as a JSON list            |
|<!-- include(partials/http_401.md) -->|
|<!-- include(partials/http_403.md) -->|
|  404 | The requested resource does not exist |

For example, to show the variable "db/password":

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + kind: variable (string) - kind of resource requested
  + identifier: db/password (string)  - the identifier of the resource

+ Request
  <!-- include(partials/auth_header_code.md) -->

+ Response 200 (application/json)

    ```
    {
        "created_at": "2017-07-25T06:30:38.768+00:00",
        "id": "mycorp:variable:db/password",
        "owner": "mycorp:user:admin",
        "policy": "mycorp:policy:root",
        "permissions": [],
        "annotations": [],
        "policy_versions": []
      }
    ]
    ```
