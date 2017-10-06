## Change your password [/authn/{account}/password]

### Change your password [PUT]

Changes a user's password. You must provide the login name and current password
or API key of the user whose password is to be updated in
an [HTTP Basic Authentication][auth] header. Also replaces the user's API key
with a new securely generated random value. You can fetch the new API key by
using [Login](#authentication-login-get).

<!-- include(partials/basic_auth.md) -->

Note that machine roles (Hosts) do not have passwords. They authenticate using
their API keys, while passwords are only used by human users.

#### Example with `curl`

Change the password of user `alice` from "beep-boop" to "EXTERMINATE":

```bash
curl --verbose \
     --request PUT --data EXTERMINATE \
     --user alice:beep-boop \
     https://eval.conjur.org/authn/myorg/password
```

Now you can verify it worked by running the same command again, which should fail, because the password has changed. If you feel like a round-trip you can swap the passwords to change it back:

```bash
curl --verbose \
     --request PUT --data beep-boop \
     --user alice:EXTERMINATE \
     https://eval.conjur.org/authn/myorg/password
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

