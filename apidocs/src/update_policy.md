### Update a policy [PATCH]

Modifies an existing [Conjur Policy](https://try.conjur.org/reference/policy.html).
Deletions can be performed with explicit `!delete` statements.

#### Example with `curl` and `jq`

Supposing you have a policy to load in `/tmp/policy.yml` (such as the sample one provided below)

```
curl -H "$(conjur authn authenticate -H)" \
     -X PATCH -d "$(< /tmp/policy.yml)" \
     https://eval.conjur.org/policies/mycorp/policy/root \
     | jq .
```

---

**Request Body**

The request body should be a policy file. For example:

TODO: add example w/ !delete

```
- !policy
```

**Response**

| Code | Description                                                                            |
|------|----------------------------------------------------------------------------------------|
|  201 | The policy was updated successfully                                                    |
| <!-- include(partials/http_401.md) -->                                                        |
| <!-- include(partials/http_403.md) -->                                                        |
|  404 | The policy referred to a role or resource that does not exist in the specified account |
|  422 | The request body was empty or the policy was not valid YAML                            |

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + identifier: root (string) - id of the policy to update

+ Response 201 (application/xml)

TODO: sample response
