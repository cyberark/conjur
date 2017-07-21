## Show Role [/roles/{account}/{kind}/{identifier}]

### Retrieve a record pertaining to a role [GET]

The response for this method is similar to what you get when creating
the role, but it **does not include the role's API key**.

If a role A is granted to a role B, then role A is said to have role B as a member. These relationships are described in the "members" portion of the returned JSON.

The `identifier` parameter must be URL-encoded.

**Permission Required**: `read` permission on resource corresponding to the role.

<!-- include(partials/role_kinds.md) -->

---

<!-- include(partials/auth_header_table.md) -->

**Response**

|Code|Description                                        |
|----|---------------------------------------------------|
|200 |The response body contains the requested record    |
|403 |You don't have permission to view the record       |
|404 |No record exists with the given kind and identifier|

Supposing the requested role is a user named Chanda at an organization called CyberArk:

+ Parameters
  + account: cyberark (string) - the organization name
  + kind: user (string) - the type of record requested (see table above)
  + identifier: chanda (string) - the identifier of the role

+ Request
  <!-- include(partials/auth_header_code.md) -->
  
+ Response 200 (application/json)
  ```json
  {
      "login":"chanda",
      "ownerid":"ci:group:developers",
      "members": [
        {
          "admin_option": false,
          "member": "cucumber:group:ops",
          "ownership": false,
          "role": "cucumber:user:chanda"
        }
      ]
  }
  ```
