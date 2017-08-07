## Create Host Factory Tokens [/host_factory_tokens]

### Create Host Factory tokens [POST]

Creates one or more tokens which can be used to bootstrap host identity.
Responds with a JSON document containing the tokens and their restrictions.

If the tokens are created with a CIDR restriction, Conjur will only accept them
from the whitelisted IP ranges.

**Permissions required**

`execute` privilege on the Host Factory.

#### Example with `curl` and `jq`

Suppose your account is `mycorp`, your host factory is called `hf-db` and you
want to create two tokens, each of which which are usable only by local
addresses `127.0.0.1` and `127.0.0.2`, expiring at "2017-08-04T22:27:20+00:00".

```bash
curl --request POST \
     --data-urlencode "expiration=2017-08-04T22:27:20+00:00" \
     --data-urlencode "host_factory=mycorp:host_factory:hf-db" \
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

**Request Body**

Parameters specifying:
1. the expiration date
2. the full ID of the Host Factory to use
3. the number of tokens to create
4. [CIDR][cidr] restrictions, if any

[cidr]: https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing

These must be URL-encoded and formatted [like form data][form-data].

[form-data]: https://developer.mozilla.org/en-US/docs/Learn/HTML/Forms/Sending_and_retrieving_form_data#The_POST_method

**Response**

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

## Use Token to Create a Host [/host_factories/hosts?id={identifier}]

### Use Token to Create a Host [POST]

Creates a Host using the Host Factory, returns a JSON description of it.

Requires a Host Factory token, which can be created using the
API: [Create Host Factory tokens][hf-tokens]. In practice, this token is usually
provided automatically as part of Conjur integration with your host provisioning
infrastrcture. (For example, see the [Puppet integration][puppet-integration].)

Note: if the token was created with a CIDR restriction, you must make this API
request from a whitelisted address. [See above][hf-tokens] for more.

[hf-tokens]: #host-factory-create-host-factory-tokens-post
[puppet-integration]: https://forge.puppet.com/conjur/conjur

#### Example with `curl` and `jq`

Supposing that you have a Host Factory token and want to create a new host
called "brand-new-host":

```bash
token="1bcarsc2bqvsxt6cnd74xem8yf15gtma71vp23y315n0z201c1jza7"

curl --request POST --data id=brand-new-host \
     --header "Authorization: Token token=\"$token\"" \
     https://eval.conjur.org/host_factories/hosts \
     | jq .
```

---

**Headers**

A token from the Host Factory must be provided as part of an HTTP
`Authorization` header. For example:

`Authorization: Token token=2c0vfj61pmah3efbgpcz2x9vzcy1ycskfkyqy0kgk1fv014880f4`

**Request Body**

The id of the host to be created, formatted like `id=brand-new-host`.

Note: the request body is *not* URL-encoded.

**Response**

| Code | Description                                                                           |
|------|---------------------------------------------------------------------------------------|
|  201 | A host was created, its definition is returned as a JSON document in the reponse body |
|  401 | Request using a CIDR-restricted token was made from an address not on the whitelist   |
|  422 | The request body was empty or is not formatted correctly                              |

+ Response 201 (application/json)

    ```json
    {
      "created_at": "2017-08-07T22:30:00.145+00:00",
      "id": "mycorp:host:brand-new-host",
      "owner": "mycorp:host_factory:hf-db",
      "permissions": [],
      "annotations": [],
      "api_key": "rq5bk73nwjnm52zdj87993ezmvx3m75k3whwxszekvmnwdqek0r"
    }
    ```
