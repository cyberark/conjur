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

## authn-local Service

authn-local is designed to be used by web services which provide custom authentication. Custom authenticators can extend the Conjur authentication capabilities by providing new types of authentication logic, such as:

* Verifying a password with an external LDAP.
* Verifying a token with GitHub.

Once an Authenticator has verified the credentials provided to it, it can use the authn-local service to get an access token which can be returned to the client. This way, the Authenticator offloads responsibility to authn-local for the token-signing algorithm and for securing the token-signing key.

### Security Considerations

authn-local should be disabled if you are not using it. You can do this by simply not creating the directory `/run/authn-local`.

If you do use authn-local, be careful about which processes have access to the Unix domain socket, because anyone with access to this socket can issue themselves a token for any role.

### How it Works

If you provide your Conjur server with a directory `/run/authn-local`, the authn-local service will listen on the Unix socket `.socket` in this directory.

To use authn-local, send a single line of JSON to the socket. The JSON should be a map which contains:

* **account** The account for which the token should be issued (example: "mycorp") (required).
* **sub** The username for which the token will be issued (example: "alice", "host/myapp-01") (required).
* **exp** The expiration time of the token (example: 1512664254) (optional).
* **cidr** A IP or CIDR restriction on the network addresses from which the token can be used (example: 172.16.0.1) (optional). **Note** Implementation of IP / CIDR verification is still a work in progress.

authn-local will respond with a Conjur access token formatted on a single line of input. For more details about access tokens, see [Cryptography / Authentication tokens](/reference/cryptography.html#authentication-tokens).
