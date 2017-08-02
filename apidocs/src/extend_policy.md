### Extend a policy [POST]

Adds policy data to the existing [Conjur Policy](https://try.conjur.org/reference/policy.html).
Deletions are not allowed.

#### Example with `curl` and `jq`

Supposing you have a policy to load in `/tmp/policy.yml` (such as the sample one provided below)

```
curl -H "$(conjur authn authenticate -H)" \
     -X POST -d "$(< /tmp/policy.yml)" \
     https://eval.conjur.org/policies/mycorp/policy/root \
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
      id: new-host
    - !variable
      id: new-variable
      owner: !host new-host
```

**Response**

| Code | Description                                                                            |
|------|----------------------------------------------------------------------------------------|
|  201 | The policy was extended successfully                                                   |
| <!-- include(partials/http_401.md) -->                                                        |
| <!-- include(partials/http_403.md) -->                                                        |
|  404 | The policy referred to a role or resource that does not exist in the specified account |
|  422 | The request body was empty or the policy was not valid YAML                            |

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + identifier: root (string) - id of the policy to extend

+ Response 201 (application/xml)

TODO: sample response