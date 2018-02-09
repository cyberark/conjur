## Show a role [/roles/{account}/{kind}/{identifier}]

### Show a role [GET]

Gets detailed information about a specific role, including the role members.

If a role A is granted to a role B, then role A is said to have role B
as a member. These relationships are described in the "members"
portion of the returned JSON.

<!-- include(partials/role_kinds.md) -->

<!-- include(partials/url_encoding.md) -->

#### Example using `curl` and `jq`

Suppose your account is "myorg" and you want to get information about the user "alice":

```
curl -H "$(conjur authn authenticate -H)" \
     https://eval.conjur.org/roles/myorg/user/alice \
     | jq .
```

---

<!-- include(partials/auth_header_table.md) -->

**Response**

| Code | Description                                       |
|------|---------------------------------------------------|
|  200 | The response body contains the requested role     |
|<!-- include(partials/http_401.md) -->|
|<!-- include(partials/http_403.md) -->|
|  404 | The requested role does not exist |

Supposing the requested role is a user named "otto" at an organization called "myorg":

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + kind: user (string) - kind of role requested
  + identifier: otto (string) - identifier of the role

+ Request
  <!-- include(partials/auth_header_code.md) -->
  
+ Response 200 (application/json)

    ```json
    {
      "created_at": "2017-08-02T18:18:42.346+00:00",
      "id": "myorg:user:alice",
      "policy": "myorg:policy:root",
      "members": [
        {
          "admin_option": true,
          "ownership": true,
          "role": "myorg:user:alice",
          "member": "myorg:policy:root",
          "policy": "myorg:policy:root"
        }
      ]
    }
    ```
