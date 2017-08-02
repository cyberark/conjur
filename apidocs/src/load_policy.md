### Load a Policy [PUT]

Loads or replaces a [Conjur Policy](https://try.conjur.org/reference/policy.html)
document. Policy objects that already exist on the server but are not explicitly
specified in the new Policy file are deleted. The caller must have `update`
privilege on the Policy.

#### Example with `curl` and `jq`

Supposing you have a Policy to load in `/tmp/policy.yml` (such as the sample one provided below)

```
curl -H "$(conjur authn authenticate -H)" \
     -X PUT -d "$(< /tmp/policy.yml)" \
     https://eval.conjur.org/policies/mycorp/policy/root \
     | jq .
```

---

**Request Body**

The request body is a Policy file. For example:

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
|  201 | The Policy was loaded or replaced successfully                                         |
| <!-- include(partials/http_401.md) -->                                                        |
| <!-- include(partials/http_403.md) -->                                                        |
|  404 | The Policy referred to a role or resource that does not exist in the specified account |
|  422 | The request body was empty or the Policy was not valid YAML                            |

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + identifier: root (string) - id of the Policy to load (`root` if no root Policy has been loaded yet)

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