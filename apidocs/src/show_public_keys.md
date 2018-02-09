## Show public keys [/public_keys/{account}/{kind}/{identifier}]

### Show public keys  [GET /public_keys/{account}/{kind}/{identifier}]

Shows all public keys for a resource as newline delimited string for compatibility with [the authorized_keys SSH format](https://en.wikibooks.org/wiki/OpenSSH/Client_Configuration_Files#.7E.2F.ssh.2Fauthorized_keys).

Returns an empty string if the resource does not exist, to prevent attackers from determining whether a resource exists.

<!-- include(partials/resource_kinds.md) -->

<!-- include(partials/url_encoding.md) -->

#### Example using `curl`

```
curl https://eval.conjur.org/public_keys/myorg/user/alice
```

---

**Response**

| Code | Description                                         |
|------|-----------------------------------------------------|
|  200 | Public keys returned as newline delimited string            |

For example, to show all the public keys for the user "alice":

+ Parameters
  + <!-- include(partials/account_param.md) -->
  + kind: user (string) - kind of resource of which to show public keys
  + identifier: alice (string)  - the identifier of the object

+ Response 200 (text/plain)

    ```
    ssh-rsa AAAAB3Nzabc2 admin@alice.com
        
    ssh-rsa AAAAB3Nza3nx alice@example.com
    ```
