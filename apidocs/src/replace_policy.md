## Replace a policy [/policies/{account}/policy/{identifier}]

### Replace a policy [PUT]

Loads or replaces a [Conjur policy](https://docs.conjur.org/Latest/en/Content/Operations/Policy/policy-intro.html)
document. 

Any policy data which already exists on the server but is **not** explicitly specified in the new policy file **will be deleted**. 

<!-- include(partials/url_encoding.md) -->

**Permissions required**

`update` privilege on the policy.

#### Example with `curl` and `jq`

Suppose you have a policy to load in `/tmp/policy.yml` (such as the sample one provided below). The following command will load this as the "root" policy, replacing any other data that may already be in this policy:

```
curl -H "$(conjur authn authenticate -H)" \
     -X PUT -d "$(< /tmp/policy.yml)" \
     https://eval.conjur.org/policies/myorg/policy/root \
     | jq .
```

---

**Request Body**

The request body is a policy file. For example:

```
- !policy
  id: database
  body:
    - !host
      id: db-host
    - !variable
      id: db-password
      owner: !host db-host
```

**Response**

| Code | Description                                                                            |
|------|----------------------------------------------------------------------------------------|
|  201 | The policy was loaded or replaced successfully                                         |
| <!-- include(partials/http_401.md) -->                                                        |
| <!-- include(partials/http_403.md) -->                                                        |
|  404 | The policy referred to a role or resource that does not exist in the specified account |
| <!-- include(partials/http_409.md) --> |
|  422 | The request body was empty or the policy was not valid YAML                            |

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + identifier: root (string) - id of the policy to load (`root` if no root policy has been loaded yet)

+ Response 201 (application/json)

    ```
    {
      "created_roles": {
        "myorg:host:database/db-host": {
          "id": "myorg:host:database/db-host",
          "api_key": "309yzpa1n5kp932waxw6d37x4hew2x8ve8w11m8xn92acfy672m929en"
        }
      },
      "version": 1
    }
    ```
