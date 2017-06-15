---
title: Installation - Client
layout: page
---

{% include toc.md key='get' %}

{% include toc.md key='get' section='download' %}

Your first option for getting the client is to download the package installer
for your platform. 

Head over to [https://github.com/conjurinc/cli-ruby/releases](https://github.com/conjurinc/cli-ruby/releases), 
and follow the appropriate installation procedure for your platform.

{% include toc.md key='get' section='docker' %}

You can also run the client in Docker. The following command will automatically
download and start the Conjur CLI from Docker Hub. 

It relies on the following environment variables:

* `CONJUR_APPLIANCE_URL` the URL to the Conjur server. 
* `CONJUR_ACCOUNT` the organization account name to use.

{% highlight shell %}
$ docker run --rm \
  -e CONJUR_APPLIANCE_URL=http://conjur <- Provide the URL to your server
  -e CONJUR_ACCOUNT=myorg <- Provide your organization account name
  conjur-cli
{% endhighlight %}

{% include toc.md key='configure' %}

TODO: Explain how to configure

TODO: Explain what the CONJUR_ACCOUNT is

{% include toc.md key='login' %}

Once you've downloaded the client, you'll login to Conjur. If you started
the server yourself, you'll need the `admin` API key or password. If 
someone else is managing the Conjur server, they will provide you with
your login information.

{% highlight shell %}
$ conjur login
Enter your username to log into Conjur: admin
Enter password for user admin (it will not be echoed):
Logged in
{% endhighlight %}

You can show your current logged-in user with `conjur whoami`:

{% highlight shell %}
$ conjur whoami
demo:user:admin
{% endhighlight %}
