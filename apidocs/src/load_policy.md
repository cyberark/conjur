### Load a policy [PUT]

Loads or replaces a [Conjur Policy](https://try.conjur.org/reference/policy.html)
document. Existing policy data that is not specified in the new policy is deleted.

#### Example with `curl` and `jq`

Supposing you have a policy to load in `/tmp/policy.yml` (such as the sample one provided below)

```
curl -H "$(conjur authn authenticate -H)" \
     -X PUT -d "$(< /tmp/policy.yml)" \
     https://eval.conjur.org/policies/mycorp/policy/root \
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

| Code | Description                             |
|------|-----------------------------------------|
|  201 | The policy was replaced successfully |
|<!-- include(partials/http_401.md) -->|
|<!-- include(partials/http_403.md) -->|
|  404 | The policy referred to an role or resource that does not exist in the specified account |
|  422 | The request body was empty or the policy was not valid YAML                             |

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + identifier: root (string) - id of the policy to load (`root` if no root policy has been loaded yet)

+ Response 201 (application/xml)

    ```
    {
      "created_roles": {
        "mycorp:host:database/db-host": {
          "id": "mycorp:host:database/db-host",
          "api_key": "309yzpa1n5kp932waxw6d37x4hew2x8ve8w11m8xn92acfy672m929en"
        }
      },
      "version": 1
    }
    ```
