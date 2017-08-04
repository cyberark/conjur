## Show public keys [/public_keys/{account}/{kind}/{identifier}]

### Show public keys  [GET /public_keys/{account}/{kind}/{identifier}]

The response to this method is all public keys for a resource as a newline delimited string for compatibility with the authorized_keys SSH format.

If the given resource does not exist, an empty string will be returned. This is to prevent attackers from determining whether a resource exists.

**Permissions Required**: No special permissions are required to call this method, since public keys are, well, public.

<!-- include(partials/resource_kinds.md) -->

#### Example using `curl` and `jq`

```
curl -H "$(conjur authn authenticate -H)" \
    https://eval.conjur.org/public_keys/mycorp/user/alice
```

---

**Response**

| Code | Description                                         |
|------|-----------------------------------------------------|
|  200 | Public keys returned as newline delimited string            |

For example, to fetch all the public keys for the user "alice":

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + kind: user (string) - kind of resource of which to fetch public keys
  + identifier: alice (string)  - the identifier of the object

+ Response 200 (text/plain)

    ```
    ssh-rsa AAAAB3Nzabc2 admin@alice.com
        
    ssh-rsa AAAAB3Nza3nx alice@example.com
    ```