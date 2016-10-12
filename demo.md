---
title: Demo
layout: page
index: 10
---

## Install Docker

Visit [https://docs.docker.com/engine/installation/](https://docs.docker.com/engine/installation/) for instructions.

## Clone the example repository

{% highlight shell %}
$ git clone https://github.com/conjurinc/api-python.git
$ cd api-python/demo
$ ./start.sh
{% endhighlight %}

## Launch Possum

The `start.sh` script launches three containers:

  1) `pg` A Postgres database to store the data.

  2) `possum` The Possum service.

  3) `client` A container with the client tools pre-installed and configured.

It also creates the data key, which is used to encrypt all sensitive information including API keys and secrets. After creating the containers, the startup script will drop you into a shell session on the `client` container:

{% highlight shell %}
$ ./start.sh
...
root@6309c4141aac:/app# 
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

## Understand the bootstrap policy

The Possum server starts up with a *bootstrap policy*, which defines a few basic objects that the rest of the system will be built on top of. The bootstrap policy used in this demo is simple. First it defines a group called `security_admin`, which is a group that will be able to administer the rest of the system. Then it defines a policy called `people`, which will define the human users and groups. And it defines a policy called `prod`, which will be populated with the production applications and services.

{% highlight yaml %}
# bootstrap.yml

- !group security_admin

- !policy
  id: people
  owner: !group security_admin

- !policy
  id: prod
  owner: !group security_admin
{% endhighlight %}

You can use the `possum` command line tool to list all the objects in the system:

{% highlight shell %}
$ possum list
Id                            Owner
----------------------------  ----------------------------
example:policy:bootstrap      example:user:admin
example:group:security_admin  example:user:admin
example:policy:people         example:group:security_admin
example:policy:prod           example:group:security_admin
{% endhighlight %}

## Add some users and groups

The next step is to add some human users and groups. You can do this by creating a policy file `people.yml` and loading it as the `people` policy. It this file, create two new groups `operations` and `frontend` and two users `owen` and `frank`, and places them into the corresponding groups.

This is a typical example of how Possum policy management works: the *bootstrap* policy defines the overall policy structure, and then individual policies are loaded into the slots defined by the bootstrap policy.

{% highlight yaml %}
# people.yml

- !group operations

- !group frontend

- !user owen

- !user frank

- !grant
  role: !group operations
  member: !user owen

- !grant
  role: !group frontend
  member: !user frank
{% endhighlight %}

The `group` and `user` statements are self-explanatory - they create new objects. The `grant` statement is a role-based access control operation; when role *A* is granted to role *B*, role *B* is said to "have" role *A*. All permissions held by role *A* are inherited by role *B*, so if role *A* can perform some operation, then role *B* can perform it as well.

**Note** For a detailed description of Possum RBAC, see the [Overview of RBAC in Conjur](https://developer.conjur.net/key_concepts/rbac.html).

Once you've defined the policy, you can use the `possum` command line to load it. The API keys of the new users are printed in the response; these can be used to authenticate as the corresponding user. 

{% highlight shell %}
$ cat people.yml | possum policy:load people -
{
    "owen": "xyz",
    "frank": "pdq"
}
{% endhighlight %}

If you lose the API key of a user, you can reset (rotate) it using the `admin` account. But for this demo, just leave the API keys in the console so that you can use them later.

Now you can use the `possum` tool to list the new groups and users:

{% highlight shell %}
$ possum list -k group
Id                               Owner                  Policy
-------------------------------  ---------------------  ------------------------
example:group:security_admin     example:user:admin     example:policy:bootstrap
example:group:people/operations  example:policy:people  example:policy:people
example:group:people/frontend    example:policy:people  example:policy:people

$ possum list -k user
Id                         Owner                  Policy
-------------------------  ---------------------  ---------------------
example:user:people/owen   example:policy:people  example:policy:people
example:user:people/frank  example:policy:people  example:policy:people
{% endhighlight %}

## Create the application policies

Now that we have human roles in the system, it's time to define the applications.

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
{
}
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
{
    "demo:host:prod/frontend/frontend-01": "abc",
    "demo:host:prod/frontend/frontend-02": "xyz"
}
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
{
}
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
example:host:prod/frontend/frontend-01
{% endhighlight %}

Logged in as `frontend-01`, fetch and print the password:

{% highlight shell %}
$ possum fetch prod/database/password
5b19270e46ccfa4c1f68e9a192d4728d
{% endhighlight %}

Success! 

