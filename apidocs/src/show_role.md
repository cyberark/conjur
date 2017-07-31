## Show a role [/roles/{account}/{kind}/{identifier}]

### Show a role [GET]

Gets detailed information about a specific role, including the role members.

If a role A is granted to a role B, then role A is said to have role B
as a member. These relationships are described in the "members"
portion of the returned JSON.

<!-- include(partials/role_kinds.md) -->

#### Example using `curl` and `jq`

```
curl -H "$(conjur authn authenticate -H)" \
     https://eval.conjur.org/resources/mycorp/user/ | jq .
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

Supposing the requested role is a user named "otto" at an organization called "mycorp":

+ Parameters
  + account: mycorp (string) - the organization name
  + kind: user (string) - the type of record requested (see table above)
  + identifier: otto (string) - the identifier of the role

+ Request
  <!-- include(partials/auth_header_code.md) -->
  
+ Response 200 (application/json)
