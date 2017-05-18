---
title: Tutorial - Application Secrets
layout: page
---

{% include bootstrap_policy.html %}

## Create the application policies

We will model a simple application in which a `frontend` service connects to a `database` server. The `frontend` and the `database` are loaded as separate policies. The `database` policy defines a `password`, which the `frontend` application is permitted to fetch. 

Before we can add the frontend and the database, we need to update the bootstrap policy to define the new policy slots. In addition, the bootstrap policy will *delegate* management of the `frontend` application to the user group `people/frontend`, and management of the `database` to the group `people/operations`. In this way, the security management of the infrastructure is decentralized and the Conjur administrator is not a bottleneck for routine policy changes (e.g. adding a new secret to an application). 

{% highlight yaml %}
# app.yml

- !group security_admin

- !policy
  id: people
  owner: !group security_admin
  body:
  - !group
    id: frontend

  - !group
    id: operations

- !policy
  id: prod
  owner: !group security_admin
  body:
  - !policy
    id: frontend

  - !policy
    id: database

- !permit
  role: !group people/frontend
  privilege: [ read, execute ]
  resource: !policy prod/frontend

- !permit
  role: !group people/operations
  privilege: [ read, execute ]
  resource: !policy prod/database
{% endhighlight %}

{% highlight shell %}
$ conjur policy load bootstrap app.yml
Loaded policy version 2
TODO: show output
{% endhighlight %}

## Define the `prod/frontend`

The `frontend` application is simply a group of machines which host the application code. Therefore, the policy will consist of:

* A layer.
* A set of hosts which belong to the layer.

Statically defining the hosts in a policy is appropriate for fairly static infrastructure. More dynamic systems such as auto-scaling groups and containerized deployments can be managed with Conjur as well. The details of these topics are covered elsewhere. 

Write the `frontend.yml`:

{% highlight yaml %}
# frontend.yml
- !layer

- &hosts
  - !host frontend-01
  - !host frontend-02

- !grant
  role: !layer
  members: *hosts
{% endhighlight %}

As with users, the API keys of any new hosts are printed out when the policy is loaded. API keys of hosts can be reset the same as users, if one should happen to be lost or compromised.

TODO: load the policy

## Define the `prod/database`

Let's continue by writing the policy `database.yml`. This policy will define the `password` which other applications can use to connect to the database. It will also `permit` to allow the `prod/frontend` layer to view and fetch the password.

{% highlight yaml %}
# database.yml
- &variables
  - !variable password

- !permit
  role: !layer ../frontend
  privilege: [ read, execute ]
  resource: *variables
{% endhighlight %}


{% highlight shell %}
$ conjur policy load prod/database database.yml
Loaded policy version 1
TODO: show output
{% endhighlight %}

Use `openssl` to generate a new random string, and store it in the password:

{% highlight shell %}
$ password=$(openssl rand -hex 16)
$ echo $password
5b19270e46ccfa4c1f68e9a192d4728d
$ conjur variable values add prod/database/password $password
Value added
{% endhighlight %}

The CLI can also be used to fetch the password:

{% highlight shell %}
$ conjur variable value prod/database/password
5b19270e46ccfa4c1f68e9a192d4728d
{% endhighlight %}

## Fetch the database password as a host

Owen can fetch the database password because he owns it. But the purpose of this example is to provide the database password to the `prod/frontend` application. 

We can simulate this by logging is as one of the frontend hosts. The login id of a host is `host/<id>`, where `<id>` is the host id defined in the policy. On the command-line it looks like this (you'll need the API key for `frontend-0`):

{% highlight shell %}
$ conjur authn login host:prod/frontend/frontend-01
Enter the password: ******
$ conjur authn whoami
{ "account": "demo", "login": "host:prod/frontend/frontend-01" }
{% endhighlight %}

Logged in as `frontend-01`, fetch and print the password:

{% highlight shell %}
$ conjur variable value prod/database/password
5b19270e46ccfa4c1f68e9a192d4728d
{% endhighlight %}

Success! 
