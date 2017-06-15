---
title: Installation - Client
layout: page
---

{% include toc.md key='get' %}

{% include toc.md key='get' section='docker' %}

You can easily download and run the Conjur CLI using the official pre-built images hosted by Docker Hub. 

If you run the container with interactive mode (`-it`), then you will get an interactive `bash` shell. Otherwise, you will run a single `conjur` command.

Here's how to run interactively:

{% highlight shell %}
$ docker run --rm \
    -it \
    conjurinc/cli5
root@5628127eac77:/# which conjur
/usr/local/bundle/bin/conjur
{% endhighlight %}

And here's how to run a single Conjur command (with arguments, it prints the help string):

{% highlight shell %}
$ docker run --rm \
    -e CONJUR_APPLIANCE_URL=http://conjur \
    -e CONJUR_ACCOUNT=myorg \
    -e CONJUR_AUTHN_LOGIN=admin \
    -e CONJUR_AUTHN_API_KEY=the-secret-api-key \   
    conjurinc/cli5
NAME
    conjur - Command-line toolkit for managing roles, resources and privileges
...
{% endhighlight %}

{% include toc.md key='get' section='source' %}

You can also build and run the CLI from source.

Start by cloning the `possum` branch of [https://github.com/conjurinc/cli-ruby](https://github.com/conjurinc/cli-ruby).

Then run `bundle`, and `bundle exec ./bin/conjur`.

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
