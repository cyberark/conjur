FORMAT: 1A

# Conjur Community Edition API

This is official documentation of the Conjur Community Edition API. It
allows you tremendous flexibility to control and manipulate your
Conjur software.

# Group Authentication

Most API calls require an authentication access token in the header. Here's how to obtain it if you're a human user:

1. Use a username and password to obtain an API key (refresh token) with the [Authentication > Login](#authentication-login-get) method.
2. Use the API key to obtain an access token with the [Authentication > Authenticate](#authentication-authenticate-post) method.

If you're a machine, your API key will be provided by your operator.

Access tokens expire after 8 minutes. You need to obtain a new token after it expires. 
Token expiration and renewal is handled automatically by the
Conjur client libraries.

## SSL verification

If you self-host Conjur, use the public key certificate you obtained when running `conjur init` for SSL verification when talking to your Conjur endpoint.
This certificate is not a secret, so you can check it into source control if needed.

For example, with curl you can use the cert like so:

```
$ curl --cacert <certfile> ...
```

<!-- include(login.md) -->

<!-- include(authenticate.md) -->

<!-- include(update_password.md) -->

<!-- include(rotate_api_key.md) -->

# Group Secrets

A Variable is an access-controlled list of encrypted data values. The values in a Variable are colloquially known as "secrets".

Only the twenty most recent values in a Variable are retained; this prevents the database from growing without bounds.

<!-- include(secrets.md) -->

# Group Role-based access control

<!-- include(show_role.md) -->

<!-- include(list_resources.md) -->

<!-- include(show_resource.md) -->
