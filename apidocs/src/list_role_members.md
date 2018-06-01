## List a role's members [/roles/{account}/{kind}/{identifier}?members{?search}{?limit}{?offset}{?count}]

### List role members [GET]

List members within a role.

<!-- include(partials/search_kind.md) -->

<!-- include(partials/list_paging.md) -->

<!-- include(partials/list_count.md) -->

<!-- include(partials/search_text.md) -->

#### Example with `curl` and `jq`

Suppose your organization name is "myorg" and you want to search for the first
two members matching the word "db":

```bash
curl -H "$(conjur authn authenticate -H)" \
     'https://eval.conjur.org/roles/myorg/group/devs?members&search=db&limit=2' \
     | jq .
```

<!-- include(partials/role_kinds.md) -->

<!-- include(partials/url_encoding.md) -->

---

<!-- include(partials/auth_header_table.md) -->

**Response**

| Code | Description                                              |
|------|----------------------------------------------------------|
|  200 | The response body contains the requested role members    |
|<!-- include(partials/http_401.md) -->|
|<!-- include(partials/http_403.md) -->|
|  404 | The requested role does not exist |

Supposing the requested members are for a group named "devs" at an organization called "myorg":

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + kind: group (string) - kind of role requested
  + identifier: devs (string) - identifier of the role

+ Request
  <!-- include(partials/auth_header_code.md) -->
  
+ Response 200 (application/json)

    ```json
    [
      {
            "admin_option": false,
            "member": "myorg:user:alice",
            "ownership": false,
            "policy": "myorg:policy:root",
            "role": "myorg:group:devs"
        },
        {
            "admin_option": false,
            "member": "myorg:user:bob",
            "ownership": false,
            "policy": "myorg:policy:root",
            "role": "myorg:group:devs"
        }
    ]
    ```
