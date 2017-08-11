## Revoke tokens [/host_factory_tokens/{token}]

### Revoke tokens [DELETE]

Revokes a token, immediately disabling it.

**Permissions required**

`update` privilege on the Host Factory.

#### Example with `curl`

Suppose you have a Host Factory Token and want to revoke it:

```bash
token="1bcarsc2bqvsxt6cnd74xem8yf15gtma71vp23y315n0z201c1jza7"

curl -i --request DELETE \
     --header "$(conjur authn authenticate -H)" \
     https://eval.conjur.org/host_factory_tokens/$token
```

---

#### Request

<!-- include(partials/auth_header_table.md) -->

#### Response

| Code | Description                               |
|------|-------------------------------------------|
|  204 | The token was revoked                     |
|<!-- include(partials/http_401.md) -->|
|  404 | Conjur did not find the specified token   |

+ Parameters
  + token: 1bcarsc2b… (string) - the Host Factory Token to revoke

+ Response 204
