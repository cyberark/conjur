FORMAT: 1A

# Conjur API

This is official documentation of the Conjur V5 API. It allows you tremendous flexibility to control and manipulate your Conjur software.

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

<!-- include(add_secret.md) -->

<!-- include(retrieve_secret.md) -->

<!-- include(batch_retrieval.md) -->

# Group Policies

<!-- include(replace_policy.md) -->

<!-- include(append_policy.md) -->

<!-- include(update_policy.md) -->

# Group Role-based access control

<!-- include(show_role.md) -->

<!-- include(list_role_members.md) -->

<!-- include(list_resources.md) -->

<!-- include(show_resource.md) -->

<!-- include(show_permitted_roles.md) -->

<!-- include(check_permission.md) -->

# Group Host Factory

<!-- include(host_factory_create_tokens.md) -->

<!-- include(host_factory_revoke_token.md) -->

<!-- include(host_factory_create_host.md) -->

# Group Public Keys

<!-- include(show_public_keys.md) -->
