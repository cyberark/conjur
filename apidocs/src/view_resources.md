## View Resources [/resources/{account}]

### List all resources [GET /resources/{account}]

Given an account, the output is a list of all visible resources.

---

<!-- include(partials/auth_header_table.md) -->

**Response**

|Code|Description                      |
|----|---------------------------------|
|200 |Resources returned as a JSON list|

+ Parameters
  + account: cyberark (string) - the organization name

+ Request
  <!-- include(partials/auth_header_code.md) -->

+ Response 200 (application/json)
  ```
  [
      "cyberark:user:chanda",
      "cyberark:layer:db"
  ]
  ```

### List one kind of resources [GET /resources/{account}/{kind}]

As above, but shows only one kind of resource.

<!-- include(partials/resource_kinds.md) -->

---

<!-- include(partials/auth_header_table.md) -->

**Response**

|Code|Description                      |
|----|---------------------------------|
|200 |Resources returned as a JSON list|

+ Parameters
  + account: cyberark (string) - the organization name
  + kind: user (string) - the kind of resource to list

+ Request
  <!-- include(partials/auth_header_code.md) -->

+ Response 200 (application/json)
  ```
  [
      "cyberark:user:chanda"
  ]
  ```

### Retrieve a record for a resource [GET /resources/{account}/{kind}/{identifier}]

The response to this method is similar to what you get when creating a
resource.

**Permissions Required**: `read` permission on the resource.

<!-- include(partials/resource_kinds.md) -->

---

<!-- include(partials/auth_header_table.md) -->

**Response**

|Code|Description                                        |
|----|---------------------------------------------------|
|200 |Role memberships returned as a JSON list           |
|403 |You don't have permission to view the record       |
|404 |No record exists with the given kind and identifier|

Supposing the requested resource is a layer called "db" at an organization called CyberArk:

+ Parameters
  + account: cyberark (string) - the organization name
  + kind: layer (string) - the type of record requested (see table above)
  + identifier: db (string)  - the identifier of the resource

+ Request
  <!-- include(partials/auth_header_code.md) -->

+ Response 200 (application/json)
  ```
  {
      "todo": "try this"
  }
  ```
