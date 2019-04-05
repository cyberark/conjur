## Append to a policy [/policies/{account}/policy/{identifier}]

### Append to a policy [POST]

Adds data to the existing [Conjur policy](https://docs.conjur.org/Latest/en/Content/Operations/Policy/policy-intro.html).
Deletions are not allowed. Any policy objects that exist on the server but
are omitted from the policy file will not be deleted and any explicit deletions in
the policy file will result in an error.

<!-- include(partials/url_encoding.md) -->

**Permissions required**

`create` privilege on the policy.

#### Example with `curl` and `jq`

Suppose you have a policy to load in `/tmp/policy.yml` (such as the sample one provided below). The following command will add data to the "root" policy:

```
curl -H "$(conjur authn authenticate -H)" \
     -X POST -d "$(< /tmp/policy.yml)" \
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
      id: new-host
    - !variable
      id: new-variable
      owner: !host new-host
```

**Response**

| Code | Description                                                                                   |
|------|-----------------------------------------------------------------------------------------------|
|  201 | The policy was extended successfully                                                          |
| <!-- include(partials/http_401.md) -->                                                               |
| <!-- include(partials/http_403.md) -->                                                               |
|  404 | The policy referred to a role or resource that does not exist in the specified account        |
| <!-- include(partials/http_409.md) --> |
|  422 | The request body was empty or the policy was not valid YAML or the policy includes a deletion |

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + identifier: root (string) - id of the policy to extend

+ Response 201 (application/json)

    ```
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
