---
title: Installation - Server
layout: page
---

The Server utilizes a 2-tier architecture, consisting of a stateless API server
and a Postgresql backend. 

There are several options for running the server.

{% include toc.md key='hosted' %}

<div class="note">
<strong>Note</strong> Hosted Conjur accounts are not for production data!
The security of the hosted accounts is not guaranteed, nor is there any uptime guarantee or SLA.
</div>

<p/>

In just a few seconds, you can obtain a hosted Conjur account for demo and evaluation purposes.

* Visit the [CLI Installers](https://github.com/conjurinc/cli-ruby/releases) page, 
and follow the appropriate installation procedure for your platform.
* Visit the [Hosted Conjur Control Panel](http://possum-cpanel-ci-conjur.herokuapp.com/) and click "New account".
* Login via a supported identity provider such as GitHub.
* Choose an organization account name (e.g. "yourname" or "yourcorp").

When you submit the form, your hosted Conjur account will be created.

{% include toc.md key='compose' %}

Run the API server and database in linked containers. 
This is the fastest way to get started, if you have Docker running.

1) Create the file `docker-compose.yml`

{% highlight yaml %}
pg:
  image: postgres:9.3

conjur:
  image: conjurinc/conjur
  command: server
  environment:
    DATABASE_URL: postgres://postgres@pg/postgres
    CONJUR_DATA_KEY:
  links:
  - pg:pg
{% endhighlight %}

2) Create the data key

{% include data-key-warning.md %}

{% highlight shell %}
$ export CONJUR_DATA_KEY=$(docker-compose run --no-deps --rm \
  conjur data-key generate)
{% endhighlight %}

3) Start the server and database

{% highlight shell %}
$ docker-compose up -d 
{% endhighlight %}

4) Create the organization account

{% include create-organization-account.md %}

{% highlight shell %}
$ docker-compose exec conjur token-key generate <account-id>
{% endhighlight %}

{% include toc.md key='docker' %}

1) Create the data key

{% include data-key-warning.md %}

{% highlight shell %}
$ export CONJUR_DATA_KEY=$(docker run --rm \
  conjur data-key generate)
{% endhighlight %}

2) Start the server and database

Run the server using Docker, and bring your own Postgresql.

{% highlight shell %}
$ docker run -d \
  --name conjur \
  -e CONJUR_DATA_KEY \
  -e DATABASE_URL=postgresql:/// <- Provide pg URL here
  -p 80:80 \ <- Provide a port mapping here
  conjur server
{% endhighlight %}

3) Create the organization account

{% include create-organization-account.md %}

{% highlight shell %}
$ docker exec conjur token-key generate <account-id>
{% endhighlight %}

{% include toc.md key='build' %}

You can "bring your own" deployment architecture by building and running the
Conjur server from source, aganist a Postgresql database of your choosing.

To proceed with this option, visit [Conjur on GitHub](https://github.com/conjurinc/possum).

{% include toc.md key='next-steps' %}

Once you have a server endpoint, you should download and configure the [Conjur CLI](/installation/client.html).

