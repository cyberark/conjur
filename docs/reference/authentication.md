---
title: Reference - Authentication
layout: page
section: reference
description: Conjur Reference - Authentication
---

## API Routes

For a full reference to authentication routes and methods, see the [Authentication](/api.html#authentication) section of the API reference.

## CLI Commands

## Login

Users can obtain their API key by logging in with their `username` and `password`.

{% highlight shell %}
$ conjur authn login joe-tester
Please enter your password (it will not be echoed): ******
Logged in
{% endhighlight %}

Once the API key is obtained, it may be used to rapidly obtain authentication tokens, which are required to use most other Conjur services.

## Authenticate

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

## Whoami

Once you are logged in, you can print your current logged-in identity
with the command `conjur authn whoami`.

{% highlight shell %}
$ conjur authn whoami
{"account":"mycorp","username":"joe-tester"}
{% endhighlight %}
