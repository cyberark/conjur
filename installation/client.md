---
title: Installation - Client
layout: page
---

### Download and Install

Your first option for getting the client is to download the package installer
for your platform. 

Head over to [https://github.com/conjurinc/cli-ruby/releases](https://github.com/conjurinc/cli-ruby/releases), 
and follow the appropriate installation procedure for your platform.

### Run in Docker

You can also run the client in Docker. The following command will automatically
download and start the Possum CLI from Docker Hub. 

It relies on the following environment variables:

* `CONJUR_APPLIANCE_URL` the URL to the Possum server. 
* `CONJUR_ACCOUNT` the organization account name to use.

{% highlight shell %}
$ docker run --rm \
  -e CONJUR_APPLIANCE_URL=http://conjur <- Provide the URL to your server
  -e CONJUR_ACCOUNT=myorg <- Provide your organization account name
  possum-cli
{% endhighlight %}

## Log in

Once you've downloaded the client, you'll login to Possum. If you started
the server yourself, you'll need the `admin` API key or password. If 
someone else is managing the Possum server, they will provide you with
your login information.

{% highlight shell %}
$ possum login
Enter your username to log into Possum: admin
Enter password for user admin (it will not be echoed):
Logged in
{% endhighlight %}

You can show your current logged-in user with `possum whoami`:

{% highlight shell %}
$ possum whoami
demo:user:admin
{% endhighlight %}
