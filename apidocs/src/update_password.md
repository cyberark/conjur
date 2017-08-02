## Change your password [/authn/{account}/password]

### Change your password [PUT]

Changes your password. In order to change your password, you must provide
your username and current password or API key in a HTTP Basic Authentication header. 
Note that the user whose password is to be updated is determined by
the value of the `Authorization` header.

In this example, we are updating the password of the user `bob`.
We set his password as '9p8nfsdafbp' when we created him, so to generate
the HTTP Basic Auth token on the command-line:

```
$ echo -n bob:9p8nfsdafbp | base64
Ym9iOjlwOG5mc2RhZmJw
```

This operation will also replace the user's API key with a securely
generated random value. You can fetch the new API key using the `login` method.

Note that machine roles such as Hosts do not have passwords. Passwords are only used by human users.

#### Example with `curl`

Change the password of user `alice` from "beep-boop" to "EXTERMINATE":

```
curl -v -X PUT --data EXTERMINATE \
     -u alice:beep-boop \
     https://eval.conjur.org/authn/mycorp/password
```

Now you can verify it worked by running the same command again, which should fail, because the password has changed. If you feel like a round-trip you can swap the passwords to change it back:

```
curl -v -X PUT --data beep-boop \
     -u alice:EXTERMINATE \
     https://eval.conjur.org/authn/mycorp/password
```

---

<!-- include(partials/auth_header_table.md) -->

**Request Body**

The new password, in the example "supersecret".

**Response**

|Code|Description                             |
|----|----------------------------------------|
|204 |The password has been changed           |
|<!-- include(partials/http_401.md) -->|
|404 |User not found                          |
|<!-- include(partials/http_422.md) -->|

+ Parameters
  + <!-- include(partials/account_param.md) -->

+ Request (text/plain)
    + Headers

        ```
        Authorization: Basic Ym9iOjlwOG5mc2RhZmJw
        ```
    
    + Body

        ```
        supersecret
        ```

+ Response 204

