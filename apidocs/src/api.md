FORMAT: 1A

# Conjur Community Edition API

This is official documentation of the Conjur Community Edition API. It
allows you tremendous flexibility to control and manipulate your
Conjur software.



# Group User authentication

Most API calls require an authentication access token in the header. Here's how to obtain it:

1. Use a username and password to obtain an API key (refresh token) with the [Authentication > Login](#user-authentication-login) route.
2. Use the API key to obtain an access token with the [Authentication > Authenticate](#user-authentication-authenticate) route.

Access tokens expire after 8 minutes. You need to obtain a new token after it expires.
Token expiration and renewal is handled automatically by the
Conjur [CLI](https://developer.conjur.net/cli) and [client libraries](https://developer.conjur.net/clients).

## SSL verification

If you self-host Conjur, use the public key you obtained when running `conjur init` for SSL verification when talking to your Conjur endpoint.
This is a *public* key, so you can check it into source control if needed.

For example, with curl you can use the cert like so:

```
$ curl --cacert <certfile> ...
```

<!-- include(login.md) -->

<!-- include(authenticate.md) -->

<!-- include(update_password.md) -->

<!-- include(rotate_api_key.md) -->

# Group Role-based access control

<!-- include(show_role.md) -->

<!-- include(view_resources.md) -->
