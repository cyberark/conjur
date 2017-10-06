## Create a host [/host_factories/hosts]

### Create a host [POST]

Creates a Host using the Host Factory and returns a JSON description of it.

Requires a Host Factory Token, which can be created using
the [create tokens][hf-tokens] API. In practice, this token is usually
provided automatically as part of Conjur integration with your host
provisioning infrastructure.

Note: if the token was created with a CIDR restriction, you must make this API
request from a whitelisted address.

[hf-tokens]: #host-factory-create-tokens-post
[puppet-integration]: https://forge.puppet.com/conjur/conjur

#### Example with `curl` and `jq`

Supposing that you have a Host Factory Token and want to create a new Host
called "brand-new-host":

```bash
token="1bcarsc2bqvsxt6cnd74xem8yf15gtma71vp23y315n0z201c1jza7"

curl --request POST --data-urlencode id=brand-new-host \
     --header "Authorization: Token token=\"$token\"" \
     https://eval.conjur.org/host_factories/hosts \
     | jq .
```

---

#### Request

**Headers**

A Host Factory Token must be provided as part of an HTTP
`Authorization` header. For example:

`Authorization: Token token=2c0vfj61pmah3efbgpcz2x9vzcy1ycskfkyqy0kgk1fv014880f4`

**Body Parameters**

<dl>
<dt>id</dt>
<dd>
  <code>string</code>
  (required)
  <span class="text-muted">
    <strong>Example:</strong> brand-new-host
  </span>
  <p>Identifier of the Host to be created. It will be created within the account of the Host Factory.</p>
</dd>
<dt>annotations</dt>
<dd>
  <code>object</code>
  (optional)
  <span class="text-muted">
    <strong>Example:</strong> {"puppet": "true", "description": "new db host"}
  </span>
  <p>Annotations to apply to the new Host</p>
</dd>
</dl>

#### Response

| Code | Description                                                                            |
|------|----------------------------------------------------------------------------------------|
|  201 | A host was created, its definition is returned as a JSON document in the response body |
|  401 | The token was invalid, expired, or the CIDR restriction was not satisfied              |
|  422 | The request body was empty or a parameter was not formatted correctly                  |

+ Response 201 (application/json)

    ```json
    {
      "created_at": "2017-08-07T22:30:00.145+00:00",
      "id": "myorg:host:brand-new-host",
      "owner": "myorg:host_factory:hf-db",
      "permissions": [],
      "annotations": [],
      "api_key": "rq5bk73nwjnm52zdj87993ezmvx3m75k3whwxszekvmnwdqek0r"
    }
    ```
