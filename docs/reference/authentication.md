---
title: Reference - Authentication
layout: page
---

Conjur authentication is based on auto-expiring tokens, which are issued by Conjur when presented with both:

* A login name
* An API key

The Conjur Token provides authentication for API calls. 

For API usage, it is ordinarily passed as an 
HTTP Authorization "Token" header.
    
```
Authorization: Token token="eyJkYX...Rhb="
```

Properties of the token include:

* It is JSON.
* It carries the login name and other data in a payload.
* It is signed by a private authentication key, and verified by a corresponding public key.
* It carries the signature of the public key for easy lookup in a public key database.
* It has a fixed life span of several minutes, after which it is no longer valid.

Before the token can be used to make subsequent calls to the API, it must be formatted. Take
the response from the `authenticate` call and base64-encode it and strip out newlines.

```
$ token=$(echo -n $response | base64 | tr -d '\r\n')
```

The token can now be used for Conjur API access.

```
$ curl --cacert <certfile> \
-H "Authorization: Token token=\"$token\"" \
<route>
```

## CLI Commands

## Login

Users can obtain their API key by logging in with their `username` and `password`.

{% highlight shell %}
$ conjur authn login joe-tester
Please enter your password (it will not be echoed): *********
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
{"account":"yourorg","username":"joe-tester"}
{% endhighlight %}

