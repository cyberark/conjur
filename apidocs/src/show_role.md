## Show Role [/roles/{account}/{kind}/{identifier}]

### Show one role [GET]

The response for this method is a JSON document describing a single role.

If a role A is granted to a role B, then role A is said to have role B
as a member. These relationships are described in the "members"
portion of the returned JSON.

The `identifier` parameter must be URL-encoded.

**Permission Required**: `read` permission on resource corresponding
to the role.

<!-- include(partials/role_kinds.md) -->

#### Example using `curl` and `jq`

```
curl -H "$(conjur authn authenticate -H)" \
     https://eval.conjur.org/resources/cyberark/user/ | jq .
```

---

<!-- include(partials/auth_header_table.md) -->

**Response**

| Code | Description                                       |
|------|---------------------------------------------------|
|  200 | The response body contains the requested role     |

Supposing the requested role is a user named Chanda, defined as part of a policy
called "ops" at an organization called CyberArk:

+ Parameters
  + account: cyberark (string) - the organization name
  + kind: user (string) - the type of record requested (see table above)
  + identifier: chanda (string) - the identifier of the role

+ Request
  <!-- include(partials/auth_header_code.md) -->
  
+ Response 200 (application/json)
  ```json
  [
    {
      "created_at": "2017-07-25T22:32:26.006+00:00",
      "id": "cyberark:user:chanda@ops",
      "owner": "cyberark:policy:ops",
      "policy": "cyberark:policy:root",
      "permissions": [],
      "annotations": []
    }
  ]
  ```
