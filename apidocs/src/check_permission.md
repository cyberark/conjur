## Check permission [/resources/{account}/{kind}/{identifier}?check=true&role={role}&privilege={privilege}]

### Check permission [GET]

Checks whether a role has a privilege on a resource. For example, is this Host
authorized to `execute` (fetch the value of) this Secret?

<!-- include(partials/resource_kinds.md) -->

<!-- include(partials/url_encoding.md) -->

#### Example with `curl`

Suppose your account name is "myorg" and you want to check whether Host
"application" can `execute` (fetch the value of) Variable "db-password":

This request has a long URL, so I break it up for you with some variables.

```bash
endpoint='https://eval.conjur.org/resources'
account='myorg'
var_id='db-password'
host_id='application'

curl -i -H "$(conjur authn authenticate -H)" \
     '$endpoint/$account/variable/$var_id?check=true&role=$account:host:$host_id&privilege=execute'
```

---

#### Request

<!-- include(partials/auth_header_table.md) -->

#### Response

| Code | Description                                                                            |
|------|----------------------------------------------------------------------------------------|
|  204 | The role has the specified privilege on the resource                                   |
|<!-- include(partials/http_401.md) -->|
|  404 | The role or resource was not found; or the role does not have the specified permission |

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + kind: variable (string) - kind of resource to test
  + identifier: db-password (string) - the identifier of the resource to test
  + role: myorg:host:application (string) - the fully qualified identifier of
    the role to test
  + privilege: execute (string) - the privilege to test on the resource

+ Request
  <!-- include(partials/auth_header_code.md) -->

+ Response 204
