## Login [/api/authn/users/login]

### Exchange a user login and password for an API key [GET]

Sending your Conjur username and password via HTTP Basic Auth to this route returns
an API key.

Once this API key is obtained, it may be used to rapidly obtain authentication tokens by calling the
[Authenticate](http://docs.conjur.apiary.io/#reference/authentication/authenticate) route.
An authentication token is required to use most other parts of the Conjur API.

The value for the `Authorization` Basic Auth header can be obtained with:

```
$ echo -n alice:secret  | base64
YWxpY2U6c2VjcmV0
```

If you log in through the command-line interface, you can print your current
logged-in identity with the `conjur authn whoami` CLI command.

Passwords are stored in the Conjur database using bcrypt with a work factor of 12.
Therefore, login is a fairly expensive operation.

---

**Headers**

|Field|Description|Example|
|----|------------|-------|
|Authorization|HTTP Basic Auth|Basic YWxpY2U6c2VjcmV0|

**Response**

|Code|Description|
|----|-----------|
|200|The response body is the API key|
|401|The credentials were not accepted|

+ Request
    + Headers
    
        ```
        Authorization: Basic YWxpY2U6c2VjcmV0
        ```
        
+ Response 200 (text/html; charset=utf-8)

    ```
    14m9cf91wfsesv1kkhevg12cdywm2wvqy6s8sk53z1ngtazp1t9tykc
    ```
