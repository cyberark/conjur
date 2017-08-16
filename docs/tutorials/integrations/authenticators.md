---
title: Tutorial - Custom Authentication
layout: page
section: tutorials
---

{% include toc.md key='introduction' %}

Conjur web service functions require an access token to authenticate virtually all requests. An access token is a cryptographically signed, time-limited JSON object.

<div class="note">
<strong>Note</strong> A host factory token is used to authenticate and authorize a request to create a new host using a host factory. All other methods which require authentication use the Conjur access token.
</div>
<p/>

A client can obtain an access token using the `authenticate` method which is described fully in the [Authentication reference](/reference/authentication.html). The credential presented to `authenticate` is an API key, which can be strengthened using an IP or CIDR restriction.

Taken together, the API key and IP/CIDR restriction can serve as reasonably strong credentials which are useful for many use cases. However, there are situations where an API key and IP/CIDR is not ideal. For example:

* When clients are rapidly created and destroyed.
* When IP addresses are not stable or cannot be constrained in a useful way.

For these situations, Conjur enables you to implement your own authentication provider. Custom authenticators should accept some domain-specific credentials, verify them, and issue an access token. This is the proper way to authenticate when BOTH of the following conditions are satisfied:

* Clients are highly ephemeral.
* An external authority is available to help verify client identity.

Some examples of environments where custom authentication is useful include Kubernetes, OpenShift, Mesos, Docker Swarm, Pivotal CloudFoundry, Jenkins, and IaaS e.g. AWS (in some cases).

{% include toc.md key='prerequisites' %}

Custom authenticators can be written in any language. However, this tutorial uses Ruby examples. So, you'll need a working Ruby environment.

It's also helpful to have a local Conjur server (e.g. in your laptop's Docker engine) so that you can directly access the database and inspect the token-signing keys.

{% include toc.md key='access-token' %}

The simplest way to write a custom authenticator is to write a Ruby webservice using a simple framework like Sinatra. This way, you can use the [slosilo](https://github.com/conjurinc/slosilo) Ruby gem which has built-in support for issuing (and verifying) Conjur access tokens. It's certainly possible to port the token-issuing code to other languages, since it uses standard cryptographic techniques. However, be aware that the Slosilo library has been reviewed by a professional cryptographic audit; therefore it is advantageous to use it without modification.

To issue an access token, you need two things:

1. A signing key, which is a 2048-bit RSA private key.
2. The identity of the role for whom you want to issue the token.

Here's a snippet showing how easy it is to issue an access token for a user called "alice":

{% highlight ruby %}
irb(main):001:0> require 'slosilo'
=> true
irb(main):002:0> key = Slosilo::Key.new
=> #<Slosilo::Key:0x00000001999098 @key=#<OpenSSL::PKey::RSA:0x00000001999048>>
irb(main):003:0> puts JSON.pretty_generate(key.signed_token('alice'))
{
  "data": "alice",
  "timestamp": "2017-06-14 15:14:04 UTC",
  "signature": "AA2x...rFnF",
  "key": "8485e4f593dd2668a062cdaecf28d5bd"
}
=> nil
{% endhighlight %}

{% include toc.md key='signing-keys' %}

In the example above, we generated a new RSA key to sign the token. You can't use this approach to make a custom authenticator, because your Conjur server won't recognize the signing key that you used.

What you need to do is use the signing key for the organization account for which you'll be issuing tokens. There are two ways that you can obtain this signing key:

1. Run your custom authenticator with a connection to the Conjur database.
1. Extract the signing key from the database and provide it to your custom authenticator.

### Using the Database-Stored Signing Key

The Conjur server stores the signing keys encrypted in the database. If your custom authenticator is configured with a database connection, you can fetch the signing key using SQL (or the Ruby object-relational helper code).

Since the signing keys are encrypted, connecting to the database is not sufficient to read one. You also need to have the encryption key, which you provide to the Conjur server using the environment variable `CONJUR_DATA_KEY`.

In Ruby code, it looks like this:

{% highlight ruby %}
# Dependencies
require 'sequel'
require 'slosilo'
require 'slosilo/adapters/sequel_adapter'

# Establish the encryption key
data_key = ENV['CONJUR_DATA_KEY']
Slosilo::encryption_key = Base64.strict_decode64 data_key.strip

# Configure the database connection
Sequel::Model.db = Sequel.connect ENV['DATABASE_URL']
Slosilo::adapter = Slosilo::Adapters::SequelAdapter.new

# Issue a token
puts Slosilo["authn:#{account}"].signed_token 'alice'
{% endhighlight %}

### Extracting the Signing Key

Keep in mind that a signing key is a very sensitive piece of data. Someone with the signing key can issue access tokens for any role in the organization account (including "admin"). So, if you extract the key from the Conjur database, be sure and keep it tighly secured. Use of an HSM or key store such as Amazon KMS is recommended.

To extract a signing key, you can run the following Ruby command:

{% highlight shell %}
$ account=myorg
$ rails r "puts Slosilo['authn:$account'].key"
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAoIb2nKwZ1klb8AVDv0PIZ9FsGwrlLDFkjyXUNNJ5lL9rvf1Z
OxQpNlTtGZ86eStSWI326KB8BTjM/LOJJH+KfKDtAL1A2v8+CaErQXnjNSXVBuLB
...
f9bh5Nh83iIPb7NxofmKIs7/VowzjOgCreP36uqcolSPSqLE4wpivGzA+fPZfkM4
7cUUmm/ijrgX5TlX5t3hEUMGI7vOE20ijuVSFq45QqVL68HtkvZiJOY=
-----END RSA PRIVATE KEY-----
{% endhighlight %}

{% include toc.md key='route' %}

The URL to obtain an access token is `POST /:account/:login/authenticate`. The parameters are:

* `account` The organization account.
* `login` The login name of the authenticating role. Because the login is part of the URL route, it must be URL-encoded.

For users, the `login` is the username (example: "alice"). For machines, the `login` is the prefix "host" followed by the host id (example: "host/prod/frontend/frontend-001", or as a URI path component "host%2Fprod%2Ffrontend%2Ffrontend-001").

The `login` is the value that should be the payload of the access token.

{% include toc.md key='example' %}

As an example, we will implement an authenticator which will always issue an access token for the user named "public".

First, install dependencies:

```
$ gem install sinatra slosilo sequel
```

Then create the file "public.rb":

{% highlight ruby %}
require 'sinatra'
require 'sequel'
require 'slosilo'
require 'slosilo/adapters/sequel_adapter'

# Establish the encryption key
data_key = ENV['CONJUR_DATA_KEY']
Slosilo::encryption_key = Base64.strict_decode64 data_key.strip

# Configure the database connection
Sequel::Model.db = Sequel.connect ENV['DATABASE_URL']
Slosilo::adapter = Slosilo::Adapters::SequelAdapter.new

post '/:account/:login/authenticate' do
  halt 422 unless login = params['login']
  halt 422 unless account = params['account']

  halt 401 unless login == "public"
  halt 404 unless key = Slosilo["authn:#{account}"]
  key.signed_token(login).to_json
end
{% endhighlight %}

Now run the authenticator in the background:

{% highlight shell %}
$ ruby public.rb &
== Sinatra (v2.0.0) has taken the stage on 3000 for development with backup from Puma
Puma starting in single mode...
* Version 3.8.2 (ruby 2.2.7-p470), codename: Sassy Salamander
* Min threads: 0, max threads: 16
* Environment: development
* Listening on tcp://localhost:3000
Use Ctrl-C to stop
{% endhighlight %}

Then send a `POST` request to authenticate as the account user "public":

{% highlight shell %}
$ curl -X POST localhost:3000/myorg/public/authenticate
{"data":"public","timestamp":"2017-06-14 18:18:26 UTC","signature":"DR_9l...c22cd"}
{% endhighlight %}

Now send a `POST` request to authenticate as the (invalid) account user "alice":

{% highlight shell %}
$ curl -i -X POST localhost:3000/myorg/alice/authenticate
HTTP/1.1 401 Unauthorized
{% endhighlight %}

{% include toc.md key='client' %}

In the example above, we used cURL to interact with the custom authenticator. How about the Conjur API clients and CLI?

These can be configured to use a custom authenticator by setting the environment variable `CONJUR_AUTHN_URL` or by setting the configuration setting `Conjur.configuration.authn_url`.

Here's how it works with the Conjur API for Ruby:

{% highlight ruby %}
require 'conjur-api'

# Use the custom authenticator
Conjur.configuration.authn_url = 'http://localhost:3000'

# Authenticate as "public"
conjur = Conjur::API.new_from_key 'public', 'api-key-not-used'
# Prints the token as a Ruby Hash
puts conjur.token

# Authenticate as "alice"
conjur = Conjur::API.new_from_key 'alice', 'api-key-not-used'
# This will fail
puts conjur.token
{% endhighlight %}

{% include toc.md key='summary' %}

In this tutorial, we've explored Conjur authentication in detail. Custom authenticators can issue access tokens if they have:

1. A strong means of authenticating the client.
2. Access to the organization account signing key.

When these two pieces of information are available, custom authentication offers a powerful strategy for authenticating ephemeral jobs and processes. Note however that an improperly developed custom authenticator is a severe security risk to the Conjur system. With great power comes great responsibility, so proceed with caution and enlist feedback and review from experienced community members.
