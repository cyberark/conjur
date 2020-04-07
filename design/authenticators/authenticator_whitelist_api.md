# Authenticator Whitelist API

## Introduction

Enabling and disabling authenticators is a common workflow when setting up Conjur
or when adding new integrations. Authenticators are defined and configured using
Conjur policy at runtime, but to enable and use an authenticator it has to first 
be whitelisted.

The authenticator whitelist was previously managed with the `CONJUR_AUTHENTICATORS`
environment variable. This, however, also requires the Conjur process to be restarted,
and often requires updates to configuration management for the Conjur container
as well.

By storing the authenticator whitelist in the Conjur database, and adding an HTTP
API endpoint to manage the whitelist, we both allow the authenticator workflow to
become more streamlined, as well as enable additional usability (e.g. enabling
or disabling authenticators using the `conjur` CLI).

## API Endpoint for Authenticator Whitelist

These endpoints require authentication and permission to read and update the
given authenticator's `!webservice` resource.

* **URL:**

    `/:authenticator/:service_id/:account`

    Example: `/authn-k8s/my-authenticator/my-company`

* **Method:**

    `PATCH`

* **URL Parameters:**

  * `:authenticator`: The authenticator type (e.g. `authn-k8s`, `authn-oidc`).
  * `:service_id`: The name of the authenticator from the policy (`!webservice <service_id>`).
  * `:account`: The Conjur account in which to enable this authenticator.

* **Request Content Type:**

    `application/x-www-form-urlencoded`

* **Body:**

    The Authenticator patch endpoint takes a single parameter, `enabled`, which
    may be set to either `true` to enable the authenticator (add it to the whitelist)
    or `false` to disable the authenticator (remove it from the whitelist).

    *Example:*

    ```
    enabled=true
    ```

* **Success Response:**

  `204 No Content`

## Examples

### Enable Authenticator

```sh
curl --request PATCH \
  --data "enabled=true" \
  https://conjur.mycompany.net/authn-k8s/my-authenticator/my-account
```

### Disable Authenticator

```sh
curl --request PATCH \
  --data "enabled=false" \
  https://conjur.mycompany.net/authn-k8s/my-authenticator/my-account
```
