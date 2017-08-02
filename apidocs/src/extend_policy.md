### Extend a Policy [POST]

Adds data to the existing [Conjur Policy](https://try.conjur.org/reference/policy.html).
Deletions are not allowed, that is any Policy objects that exist on the server but
are omitted from the Policy file will not be deleted and any explicit deletions in
the Policy file will result in an error.

The caller must have `create` privilege on the Policy.

#### Example with `curl` and `jq`

Supposing you have a Policy to load in `/tmp/policy.yml` (such as the sample one provided below)

```
curl -H "$(conjur authn authenticate -H)" \
     -X POST -d "$(< /tmp/policy.yml)" \
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
      id: new-host
    - !variable
      id: new-variable
      owner: !host new-host
```

**Response**

| Code | Description                                                                                   |
|------|-----------------------------------------------------------------------------------------------|
|  201 | The Policy was extended successfully                                                          |
| <!-- include(partials/http_401.md) -->                                                               |
| <!-- include(partials/http_403.md) -->                                                               |
|  404 | The Policy referred to a role or resource that does not exist in the specified account        |
|  422 | The request body was empty or the Policy was not valid YAML or the Policy includes a deletion |

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + identifier: root (string) - id of the Policy to extend

+ Response 201 (application/xml)

    ```
    Loaded policy 'root'
    {
      "created_roles": {
        "cucumber:host:database/new-host": {
          "id": "cucumber:host:database/new-host",
          "api_key": "1n1k85r3pcs7av2mmpj233jajndc1bx8ma52rwybj31c487r72zree1c"
        }
      },
      "version": 2
    }
    ```