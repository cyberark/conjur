---
title: Tutorial - Application Secrets
layout: page
---

{% include bootstrap_policy.html %}

## Create the application policies

We will model a simple application in which a `frontend` service connects to a `database` server. The `frontend` and the `database` are loaded as separate policies. The `database` policy defines a `password`, which the `frontend` application is permitted to fetch. 

Before we can add the frontend and the database, we need to update the bootstrap policy to define the new policy slots. In addition, the bootstrap policy will *delegate* management of the `frontend` application to the user group `people/frontend`, and management of the `database` to the group `people/operations`. In this way, the security management of the infrastructure is decentralized and the Possum administrator is not a bottleneck for routine policy changes (e.g. adding a new secret to an application). 

{% highlight yaml %}
# bootstrap.yml

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
$ cat bootstrap.yml | possum policy:load bootstrap -
Loaded policy version 2
{% endhighlight %}

## Define the `prod/frontend`

The `frontend` application is simply a group of machines which host the application code. Therefore, the policy will consist of:

* A layer.
* A set of hosts which belong to the layer.

Statically defining the hosts in a policy is appropriate for fairly static infrastructure. More dynamic systems such as auto-scaling groups and containerized deployments can be managed with Possum as well. The details of these topics are covered elsewhere. 

Write the `frontend.yml`:

{% highlight yaml %}
- !layer

- &hosts
  - !host frontend-01
  - !host frontend-02

- !grant
  role: !layer
  members: *hosts
{% endhighlight %}

As with users, the API keys of any new hosts are printed out when the policy is loaded. API keys of hosts can be reset the same as users, if one should happen to be lost or compromised.

To demonstrate how delegation works, we will login as frank, who belongs to the frontend group. Enter Frank’s API key at the login prompt.

{% highlight shell %}
$ possum login
Enter your username to log into Possum: frank@people
Enter the password: ******
$ possum whoami
demo:user:frank@people
{% endhighlight %}

Then Frank can load `prod/frontend` policy:

{% highlight shell %}
$ cat frontend.yml | possum policy:load prod/frontend -
Loaded policy version 1
Created 2 roles

Id                                   API Key
-----------------------------------  -----------------------------------------------------
demo:host:prod/frontend/frontend-01  b57k1j2vb5pnx2rkpjvt5jkbbc1j13t38236c38esn6pak1f0yb28
demo:host:prod/frontend/frontend-02  3p2aryd3rdk2m816jysdk3n2se3wmpy1s23954hvckmfsgcbkpsjw
{% endhighlight %}

## Define the `prod/database`

Let's continue by writing the policy `database.yml`. This policy will define the `password` which other applications can use to connect to the database. It will also `permit` to allow the `prod/frontend` layer to view and fetch the password.

{% highlight yaml %}
- &variables
  - !variable password

- !permit
  role: !layer ../frontend
  privilege: [ read, execute ]
  resource: *variables
{% endhighlight %}

Load the database policy:

{% highlight shell %}
$ cat database.yml | possum policy:load prod/database -
Error 403: Forbidden
{% endhighlight %}

Whoops! We are still logged in as Frank, and Frank doesn't have permission to manage the prod/database policy. This is Possum's RBAC in action. 

To fix the problem, login as `owen`, who belongs to the operations group. Enter Owen's API key at the login prompt.

{% highlight shell %}
$ possum login
Enter your username to log into Possum: owen@people
Enter the password: ******
{% endhighlight %}

Then Owen can load `prod/database` policy:

{% highlight shell %}
$ cat database.yml | possum policy:load prod/database -
Loaded policy version 1
{% endhighlight %}

Because Owen owns the `prod/database` policy, he has full management over the objects in it. This means that he can also load a new value into the `password` variable. Use `openssl` to generate a new random string, and store it in the password:

{% highlight shell %}
$ password=$(openssl rand -hex 16)
$ echo $password
5b19270e46ccfa4c1f68e9a192d4728d
$ possum store prod/database/password $password
Value added
{% endhighlight %}

The CLI can also be used to fetch the password:

{% highlight shell %}
$ possum fetch prod/database/password
5b19270e46ccfa4c1f68e9a192d4728d
{% endhighlight %}

## Fetch the database password as a host

Owen can fetch the database password because he owns it. But the purpose of this example is to provide the database password to the `prod/frontend` application. 

We can simulate this by logging is as one of the frontend hosts. The login id of a host is `host/<id>`, where `<id>` is the host id defined in the policy. On the command-line it looks like this (you'll need the API key for `frontend-0`):

{% highlight shell %}
$ possum login -r host:prod/frontend/frontend-01
Enter the password: ******
$ possum whoami
demo:host:prod/frontend/frontend-01
{% endhighlight %}

Logged in as `frontend-01`, fetch and print the password:

{% highlight shell %}
$ possum fetch prod/database/password
5b19270e46ccfa4c1f68e9a192d4728d
{% endhighlight %}

Success! 

