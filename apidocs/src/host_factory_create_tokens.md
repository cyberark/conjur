## Create tokens [/host_factory_tokens]

### Create tokens [POST]

Creates one or more tokens which can be used to bootstrap host identity.
Responds with a JSON document containing the tokens and their restrictions.

If the tokens are created with a CIDR restriction, Conjur will only accept them
from the whitelisted IP ranges.

**Permissions required**

`execute` privilege on the Host Factory.

#### Example with `curl` and `jq`

Suppose your account is `myorg`, your host factory is called `hf-db` and you
want to create two tokens, each of which which are usable only by local
addresses `127.0.0.1` and `127.0.0.2`, expiring at "2017-08-04T22:27:20+00:00".

```bash
curl --request POST \
     --data-urlencode "expiration=2017-08-04T22:27:20+00:00" \
     --data-urlencode "host_factory=myorg:host_factory:hf-db" \
     --data-urlencode "count=2" \
     --data-urlencode "cidr[]=127.0.0.1" \
     --data-urlencode "cidr[]=127.0.0.2" \
     -H "$(conjur authn authenticate -H)" \
     https://eval.conjur.org/host_factory_tokens \
     | jq .
```

Note 1: `curl` will automatically encode your `POST` body if you use the
`--data-urlencode` option. If your HTTP/REST client doesn't support this
feature, you can [do it yourself][mdn-urlencode].

Note 2: in this example, the two provided addresses are logical OR-ed together
and apply to both tokens. If you wanted each token to have a *different* CIDR
restriction, you would make two API calls each with `count=1`.

[mdn-urlencode]: https://developer.mozilla.org/en-US/docs/Glossary/percent-encoding

---

#### Request

**Body Parameters**

<dl>
<dt>expiration</dt>
<dd>
  <code>ISO 8601 datetime string</code>
  (required)
  <span class="text-muted">
    <strong>Example:</strong> 2017-08-04T22:27:20+00:00
  </span>
  <p>Expiration date of the token</p>
</dd>
<dt>host_factory</dt>
<dd>
  <code>string</code>
  (required)
  <span class="text-muted">
    <strong>Example:</strong> myorg:host_factory:hf-db
  </span>
  <p>Fully qualified Host Factory id</p>
</dd>
<dt>count</dt>
<dd>
  <code>integer</code>
  (optional, default=1)
  <span class="text-muted">
    <strong>Example:</strong> 2
  </span>
  <p>Number of tokens to create</p>
</dd>
<dt>cidr</dt>
<dd>
  <code>array</code>
  (optional)
  <span class="text-muted">
    <strong>Example:</strong> ["127.0.0.1","127.0.0.2"]</span>
  <p><a href="https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing">CIDR</a> restriction(s) on token usage</p>
</dd>
</dl>

#### Response

| Code | Description                                                         |
|------|---------------------------------------------------------------------|
| 200  | Zero or more tokens were created and delivered in the response body |
|<!-- include(partials/http_403.md) -->|
| 404  | Conjur did not find the specified Host Factory                      |
|<!-- include(partials/http_422.md) -->|

+ Response 200 (application/json)

    ```json
    [
      {
        "expiration": "2017-08-04T22:27:20+00:00",
        "cidr": [
          "127.0.0.1/32",
          "127.0.0.2/32"
        ],
        "token": "281s2ag1g8s7gd2ezf6td3d619b52t9gaak3w8rj0p38124n384sq7x"
      },
      {
        "expiration": "2017-08-04T22:27:20+00:00",
        "cidr": [
          "127.0.0.1/32",
          "127.0.0.2/32"
        ],
        "token": "2c0vfj61pmah3efbgpcz2x9vzcy1ycskfkyqy0kgk1fv014880f4"
      }
    ]
    ```
