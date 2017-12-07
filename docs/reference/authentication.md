---
title: Reference - Authentication
layout: page
section: reference
description: Conjur Reference - Authentication
---

## API Routes

For a full reference to authentication routes and methods, see the [Authentication](/api.html#authentication) section of the API reference.

## CLI Commands

### Login

Users can obtain their API key by logging in with their `username` and `password`.

{% highlight shell %}
$ conjur authn login joe-tester
Please enter your password (it will not be echoed): ******
Logged in
{% endhighlight %}

Once the API key is obtained, it may be used to rapidly obtain authentication tokens, which are required to use most other Conjur services.

### Authenticate

Once you are logged in, you can use the CLI to get an authentication token which is pre-formatted
for use as an HTTP authorization header:

{% highlight shell %}
$ token=$(conjur authn authenticate -H)
$ curl -H "$token" http://conjur/resources/myaccount
[
  ... json output
]
{% endhighlight %}

If you omit the `-H` option, you get the token as JSON.

### Whoami

Once you are logged in, you can print your current logged-in identity
with the command `conjur authn whoami`.

{% highlight shell %}
$ conjur authn whoami
{"account":"myorg","username":"joe-tester"}
{% endhighlight %}

## `authn-local`

If you provide your Conjur server with a directory `/run/authn-local`, Conjur will run a service called `authn-local` which listens on a Unix socket in this directory.

You can send JSON requests to this socket. Each request must be formatted on a single line (no "pretty-printed" JSON). The JSON is a map which contains:

* **account** The account for which the token should be issued (required).
* **sub** The token subject (required).
* **exp** The expiration time of the token (optional).
* **cidr** A CIDR restriction on token validity (optional).

The response will be a Conjur access token. For more details about access tokens, see [Cryptography / Authentication tokens](/reference/cryptography.html#authentication-tokens).

`authn-local` is designed to be used by web services which provides custom authentication. Authenticators are responsible for implementing custom authentication logic, such as:

* Verifying a password with an external LDAP.
* Verifying a token with GitHub.

Once an Authenticator has verified the credentials provided to it, it can use `authn-local` to get an access token which can be returned to the client.

### Security Considerations

`authn-local` should be disabled if you are not using it. You can do this by simply not creating the directory `/run/authn-local`.

If you do use `authn-local`, be careful about which processes have access to the Unix domain socket, because anyone with access to this socket can issue themselves a token for any role. 



