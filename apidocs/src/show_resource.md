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
|  401 | Not authenticated                                   |
|  403 | You don't have permission to view the object        |
|  404 | No record exists with the given kind and identifier |

Supposing the requested resource is a layer called "db" at an organization called mycorp:

+ Parameters
  + account: mycorp (string) - the organization name
  + kind: policy (string) - the type of record requested (see table above)
  + identifier: app-prod (string)  - the identifier of the resource

+ Request
  <!-- include(partials/auth_header_code.md) -->

+ Response 200 (application/json)

    ```
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
