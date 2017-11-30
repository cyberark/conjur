---
title: Install Conjur
layout: page
section: get-started
description: Install Conjur locally yourself using Docker and the official Conjur containers on DockerHub
---

You can easily download and run the Conjur software using Docker and the
official Conjur containers on DockerHub.

{% include toc.md key='prereq' %}

1. [Install Docker Toolbox][get-docker], available for Windows and macOS.

   If you're using GNU/Linux, [follow instructions here][get-docker-gnu].

{:start="2"}
2. Install a terminal application if you don't have one already.
   [Hyper](https://hyper.is) is nice.

{% include toc.md key='launch' %}

1. In your terminal, download the Conjur quick-start configuration:

{% highlight shell %}
$ curl -o docker-compose.yml https://www.conjur.org/get-started/docker-compose.quickstart.yml
{% endhighlight %}

{:start="2"}
2. Pull all the required Docker images from DockerHub

   `docker-compose` can do this for you automatically:

{% highlight shell %}
$ docker-compose pull
{% endhighlight %}

{:start="3"}
3. Generate your master data key and load it into the environment:

{% highlight shell %}
$ docker-compose run --no-deps --rm conjur data-key generate > data_key
$ export CONJUR_DATA_KEY="$(< data_key)"
{% endhighlight %}

<div class="alert alert-info" role="alert"> <strong>Prevent data loss:</strong><br>
  The <code>conjurctl conjur data-key generate</code> command gives you a master data key.
  Back it up in a safe location.
</div>

{% include toc.md key='install' %}

1. Run `docker-compose up -d` to run the Conjur server, database and client
2. Create a default account (eg. `quick-start`):

{% highlight shell %}
$ docker-compose exec conjur conjurctl account create quick-start
{% endhighlight %}

 <div class="alert alert-info" role="alert"> <strong>Prevent data loss:</strong><br>
  The <code>conjurctl account create</code> command gives you the public key and admin API
  key for the account you created. Back them up in a safe location.
 </div>

{% include toc.md key='connect' %}

1. Run `docker-compose exec client bash` to get a bash shell with the Conjur
   client software
2. Initialize the Conjur client using the account name and admin API key you
   created:

{% highlight shell %}
$ conjur init -u conjur -a quick-start # or whatever account you created
$ conjur authn login -u admin
Please enter admin\'s password (it will not be echoed):
{% endhighlight %}

{% include toc.md key='explore' %}

Conjur is installed and ready for use! If you want to confirm that Conjur was installed properly, you can open a browser and go to _localhost:8080_ and view the included status UI page.

Ready to do more?  Here are some suggestions:

{% highlight shell %}
$ conjur authn whoami
$ conjur help
$ conjur help policy load
{% endhighlight %}

{% include toc.md key='next-steps' %}

* Go through the [Conjur Tutorials](/tutorials/)
* View Conjur's [API Documentation](/api.html)
* Secure the server with an [NGINX Proxy](/tutorials/integrations/nginx.html)

[get-docker]: https://www.docker.com/products/docker-toolbox
[get-docker-gnu]: install-docker-on-gnu-linux.html
