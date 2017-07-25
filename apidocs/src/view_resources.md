## View Resources [/resources/{account}]

### Show all resources [GET /resources/{account}]

Given an account, the output is a JSON document describing all visible resources.

---

<!-- include(partials/auth_header_table.md) -->

**Response**

| Code | Description                       |
|------|-----------------------------------|
|  200 | Resources returned as a JSON list |

+ Parameters
  + account: cyberark (string) - the organization name

+ Request
  <!-- include(partials/auth_header_code.md) -->

+ Response 200 (application/json)

    ```
    [
      {
        "created_at": "2017-07-25T06:30:38.768+00:00",
        "id": "cyberark:variable:app-prod/db-password",
        "owner": "cyberark:policy:app-prod",
        "policy": "cyberark:policy:root",
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
        "id": "cyberark:policy:app-prod",
        "owner": "cyberark:user:admin",
        "policy": "cyberark:policy:root",
        "permissions": [],
        "annotations": [],
        "policy_versions": []
      }
    ]
    ```

### Show one kind of resource [GET /resources/{account}/{kind}]

The response to this method is a JSON document describes all resources of only one kind.

<!-- include(partials/resource_kinds.md) -->

#### Example using `curl` and `jq`

```
curl -H "$(conjur authn authenticate -H)" \
    https://eval.conjur.org/resources/cyberark/variable/ \
    | jq .
```

---

<!-- include(partials/auth_header_table.md) -->

**Response**

| Code | Description                       |
|------|-----------------------------------|
|  200 | Resources returned as a JSON list |

+ Parameters
  + account: cyberark (string) - the organization name
  + kind: variable (string) - the kind of resource to list

+ Request
  <!-- include(partials/auth_header_code.md) -->

+ Response 200 (application/json)

    ```
    [
      {
        "created_at": "2017-07-25T06:30:38.768+00:00",
        "id": "cyberark:variable:app-prod/db-password",
        "owner": "cyberark:policy:app-prod",
        "policy": "cyberark:policy:root",
        "permissions": [],
        "annotations": [],
        "secrets": [
          {
            "version": 1
          }
        ]
      }
    ]
    ```

### Show one resource [GET /resources/{account}/{kind}/{identifier}]

The response to this method is a JSON document describing a single resource.

**Permissions Required**: `read` permission on the resource.

<!-- include(partials/resource_kinds.md) -->

#### Example using `curl` and `jq`

```
curl -H "$(conjur authn authenticate -H)" \
    https://eval.conjur.org/resources/cyberark/policy/app-prod \
    | jq .
```

---

<!-- include(partials/auth_header_table.md) -->

**Response**

| Code | Description                                         |
|------|-----------------------------------------------------|
|  200 | Role memberships returned as a JSON list            |
|  403 | You don't have permission to view the record        |
|  404 | No record exists with the given kind and identifier |

Supposing the requested resource is a layer called "db" at an organization called CyberArk:

+ Parameters
  + account: cyberark (string) - the organization name
  + kind: policy (string) - the type of record requested (see table above)
  + identifier: app-prod (string)  - the identifier of the resource

+ Request
  <!-- include(partials/auth_header_code.md) -->

+ Response 200 (application/json)

    ```
    {
        "created_at": "2017-07-25T06:30:38.768+00:00",
        "id": "cyberark:policy:app-prod",
        "owner": "cyberark:user:admin",
        "policy": "cyberark:policy:root",
        "permissions": [],
        "annotations": [],
        "policy_versions": []
      }
    ]
    ```
