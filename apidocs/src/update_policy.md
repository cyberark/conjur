## Update a policy [/policies/{account}/policy/{identifier}]

### Update a policy [PATCH]

Modifies an existing [Conjur policy](https://docs.conjur.org/Latest/en/Content/Operations/Policy/policy-intro.html).
Data may be explicitly deleted using the `!delete`, `!revoke`, and `!deny` statements. Unlike "replace" mode, no data is ever implicitly deleted.

<!-- include(partials/url_encoding.md) -->

**Permissions required**

`update` privilege on the policy.

#### Example with `curl` and `jq`

Suppose you have a policy to load in `/tmp/policy.yml` (such as the sample one provided below). The following command will create and delete data in the "root" policy:

```
curl -H "$(conjur authn authenticate -H)" \
     -X PATCH -d "$(< /tmp/policy.yml)" \
     https://eval.conjur.org/policies/myorg/policy/root \
     | jq .
```

---

**Request Body**

The request body should be a policy file. For example:

```
- !policy
  id: database
  body:
    - !host
      id: another-host
    - !delete
      record: !host new-host
```

**Response**

| Code | Description                                                                            |
|------|----------------------------------------------------------------------------------------|
|  201 | The policy was updated successfully                                                    |
| <!-- include(partials/http_401.md) -->                                                        |
| <!-- include(partials/http_403.md) -->                                                        |
|  404 | The policy referred to a role or resource that does not exist in the specified account |
| <!-- include(partials/http_409.md) --> |
|  422 | The request body was empty or the policy was not valid YAML                            |

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + identifier: root (string) - id of the policy to update

+ Response 201 (application/json)

    ```
    {
      "created_roles": {
        "cucumber:host:database/another-host": {
          "id": "cucumber:host:database/another-host",
          "api_key": "zcpanf1qj0be1spqmq51yfj69j24akjy413gsv501eqbf48136cw7v"
        }
      },
      "version": 3
    }
    ```
