---
title: Tutorial - Ruby API
layout: page
---

{% include toc.md key='introduction' %}

The [Conjur API for Ruby](https://github.com/conjurinc/api-ruby) provides a robust programmatic interface to Conjur. You can use the Ruby API to authenticate with Conjur, load policies, fetch secrets, perform permission checks, and more.

{% include toc.md key='prerequisites' %}

* A [Conjur server](/conjur/installation/server.html) endpoint.
* The [Conjur API for Ruby](https://github.com/conjurinc/api-ruby), version 5.0 or later.

{% include toc.md key='setup' %}

To demonstrate the usage the Conjur API, we need some sample data loaded into the server.

Save this file as "conjur.yml":

{% include policy-file.md policy='api_integration' %}

It defines:

* `variable:db/password` Contains the database password.
* `webservice:backend`
* `layer:myapp` A layer (group of hosts) with access to the password and the webservice.

Load the policy using the following command:

{% highlight shell %}
$ conjur policy load --replace bootstrap conjur.yml
Loaded policy 'bootstrap'
{
  "created_roles": {
    "dev:host:myapp-01": {
      "id": "dev:host:myapp-01",
      "api_key": "1wgv7h2pw1vta2a7dnzk370ger03nnakkq33sex2a1jmbbnz3h8cye9"
    }
  },
  "version": 1
}
{% endhighlight %}

Now, use OpenSSL to generate a random secret, and load it into the database password variable:

{% include db-password.md %}

{% include toc.md key='configuration' %}

The Ruby API is configured using the `Conjur.configuration` object. The most important options are:

* `appliance_url` The URL to the Conjur server.
* `account` The Conjur organization account name.

Create a new Ruby program, require the `conjur-api` library, and set these two parameters in the following manner:

{% highlight ruby %}
irb(main)> require 'conjur-api'
irb(main)> Conjur.configuration.appliance_url = "https://possum-ci-conjur.herokuapp.com"
irb(main)> Conjur.configuration.account = "dev" # <- REPLACE ME!
{% endhighlight %}

<div class="note">
<strong>Note</strong> Configuration can also be provided via environment variables. The environment variable pattern is <tt>CONJUR_&lt;setting></tt>. For example, <tt>CONJUR_APPLIANCE_URL=https://possum-ci-conjur.herokuapp.com</tt>
</div>

{% include toc.md key='authentication' %}

Once the server connection is configured, the next step is to authenticate to obtain an access token. When you create a Conjur Host, the server issues an API key which you can use to authenticate as that host. Here's how you use it in Ruby:

{% highlight ruby %}
irb(main)> host_id = "host/myapp-01"
irb(main)> api_key = "1vgw4jzvyzmay95mrx2s5ad1d28gt3gh2gesb1411kqcah3nrv01r"
irb(main)> conjur = Conjur::API.new_from_key host_id, api_key
irb(main)> puts conjur.token
{"data"=>"admin", "timestamp"=>"2017-06-01 13:26:59 UTC", "signature"=>"NBc5...a7LLJl", "key"=>"ccd789173e1fc4770ac66cd1acf498b4"}
{% endhighlight %}

<div class="note">
<strong>Note</strong> Authentication credentials can also be provided via environment variables. Use <tt>CONJUR_AUTHN_LOGIN</tt> for the login name, and
<tt>CONJUR_AUTHN_API_KEY</tt> for the API key.
</div>

{% include toc.md key='secrets-fetching' %}

Once authenticated, the API client can be used to fetch the database password:

{% highlight ruby %}
irb(main)> variable = conjur.resource("#{Conjur.configuration.account}:variable:db/password")
irb(main)> puts variable.value
ef0a4822539369659fbfb267
{% endhighlight %}

{% include toc.md key='permission-checking' %}

To check a permission, load the Conjur resource (typically a Webservice) on which the permission is defined.

Then use the `permitted?` method to test whether the Conjur user has a specified privilege on the resource.

In this example, we determine that `host:myapp-01` is permitted to `execute` but not `update` the resource `webservice:backend`:

{% highlight ruby %}
irb(main)> webservice = conjur.resource("#{Conjur.configuration.account}:webservice:backend")
irb(main)> puts webservice.permitted? 'execute'
true
irb(main)> puts webservice.permitted? 'update'
false
{% endhighlight %}

{% include toc.md key='webservice-authz' %}

Conjur can provide a declarative system for authenticating and authorizing access to web services. As we have seen above, the first step is to create a `!webservice` object in a policy. Then, privileges on the web service can be managed using `!permit` and `!grant`. 

In the runtime environment, a bit of code will intercept the inbound request and check for authentication and authorization. Here's how to simulate that in an interactive Ruby session.

First, the web service client will authenticate with Conjur to obtain an access token. Then this token is formed into an HTTP Authorization header:

{% highlight ruby %}
irb(main)> token = conjur.token
irb(main)> require 'base64'
irb(main)> token_header = %Q(Token token="#{Base64.strict_encode64 token.to_json}")
=> "Authorization: Token token=\"eyJkYXRh...k4YjQifQ==\""
{% endhighlight %}

Of course, the client does not have to be Ruby, it can be any language or even a tool like cURL.

On the server side, the HTTP request is intercepted and the access token is parsed out of the header. 

{% highlight ruby %}
irb(main)> token_header[/^Token token="(.*)"/]
irb(main)> token = JSON.parse(Base64.decode64($1))
{% endhighlight %}

Once the token is obtained, it can be used to construct a `Conjur::API` object. Then the `webservice` resource is obtained from the Conjur API, and the permission check is performed:

{% highlight ruby %}
irb(main)> conjur = Conjur::API.new_from_token token
irb(main)> webservice = conjur.resource("#{Conjur.configuration.account}:webservice:backend")
irb(main)> puts webservice.permitted? 'execute'
true
{% endhighlight %}

If the token is expired or invalid, then the Conjur API will raise an authentication error. If the token is valid, but the client does not have the requested privilege, then `permitted?` will return `false`. In either case, the authorization interceptor should deny access to the web service function.

Note that different web service functions may have different required privileges. For example, a `GET` method may require `read`, and a `DELETE` method may require `update`. The semantic mapping between the web service methods and the Conjur privileges is up to you.

{% include toc.md key='next-steps' %}

* Read the [Ruby API code on GitHub](https://github.com/conjurinc/api-ruby).
* Visit the [Ruby API code on RubyGems](https://rubygems.org/gems/conjur-api).


