### Update a Policy [PATCH]

Modifies an existing [Conjur Policy](https://try.conjur.org/reference/policy.html).
Policy objects may be deleted with the `!delete`, `!revoke`, and `!deny` flags. The
caller must have `update` privilege on the Policy.

#### Example with `curl` and `jq`

Supposing you have a Policy to load in `/tmp/policy.yml` (such as the sample one provided below)

```
curl -H "$(conjur authn authenticate -H)" \
     -X PATCH -d "$(< /tmp/policy.yml)" \
     https://eval.conjur.org/policies/mycorp/policy/root \
     | jq .
```

---

**Request Body**

The request body should be a Policy file. For example:

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
|  201 | The Policy was updated successfully                                                    |
| <!-- include(partials/http_401.md) -->                                                        |
| <!-- include(partials/http_403.md) -->                                                        |
|  404 | The Policy referred to a role or resource that does not exist in the specified account |
|  422 | The request body was empty or the Policy was not valid YAML                            |

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + identifier: root (string) - id of the Policy to update

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
