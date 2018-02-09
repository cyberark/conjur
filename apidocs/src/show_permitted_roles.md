## Show permitted roles [/resources/{account}/{kind}/{identifier}?permitted_roles=true&privilege={privilege}]

### Show permitted roles [GET]

Lists the roles which have the named permission on a resource.

<!-- include(partials/resource_kinds.md) -->

<!-- include(partials/url_encoding.md) -->

#### Example with `curl` and `jq`

Suppose your organization name is "myorg" and you want to find out which roles
have `execute` privileges on the Variable `db-password`, and can thus fetch the
secret:

```bash
curl -H "$(conjur authn authenticate -H)" \
     'https://eval.conjur.org/resources/myorg/variable/db-password?permitted_roles=true&privilege=execute' \
     | jq .
```

---

#### Request

<!-- include(partials/auth_header_table.md) -->

#### Response

| Code | Description                             |
|------|-----------------------------------------|
|  200 | Permitted roles returned as a JSON list |
|<!-- include(partials/http_401.md) -->|
|<!-- include(partials/http_403.md) -->|
|  404 | The specified resource does not exist   |
|<!-- include(partials/http_422.md) -->|

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + kind: variable (string) - kind of resource requested
  + identifier: db-password (string) - the identifier of the resource
  + privilege: execute (string) - roles permitted to exercise this privilege are
    shown

+ Request
  <!-- include(partials/auth_header_code.md) -->

+ Response 200 (application/json)

    ```json
    [
      "myorg:policy:database",
      "myorg:user:db-admin",
      "myorg:host:database/db-host"
    ]
    ```
