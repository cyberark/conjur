---
title: Installation - Client
layout: page
---

## Get the Client

There are two options for getting the client.

### Download

https://github.com/conjurinc/cli-ruby/releases

Follow the appropriate installation procedure for your platform.

### Docker

You can also run the client in Docker:

{% highlight shell %}
$ docker run --rm \
  -e CONJUR_APPLIANCE_URL=http://conjur <- Provide the URL to your server
  possum-client
{% endhighlight %}

## Log in

To start working with Possum, log in as the `admin` user. The password is "secret":

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
