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

Note that machine roles such as Hosts do not have passwords. Passwords are only use by human users.

---

<!-- include(partials/auth_header_table.md) -->

**Request Body**

The new password, in the example "supersecret".

**Response**

|Code|Description                             |
|----|----------------------------------------|
|204 |The password has been changed           |
|401 |Invalid or missing Authorization header |
|404 |User not found                          |
|422 |New password not present in request body|

+ Parameters
  + account: mycorp (string) - name of the account to use

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

