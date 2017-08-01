### Update a policy [PATCH]

Modifies an existing [Conjur Policy](https://try.conjur.org/reference/policy.html).
Deletions can be performed with explicit `!delete` statements.

**Request Body**

The request body should be a policy file. For example:

```
- !policy
  id: db
  body:
  - &variables
    - !variable password

  - !group secrets-users

  - !permit
    resource: *variables
    privileges: [ read, execute ]
    roles: !group secrets-users
```

**Response**

| Code | Description                             |
|------|-----------------------------------------|
|  201 | The policy was updated successfully |
|<!-- include(partials/http_401.md) -->|
|<!-- include(partials/http_403.md) -->|
|<!-- include(partials/http_422.md) -->|

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + identifier: admins (string) - id of the policy

+ Response 201 (application/xml)
