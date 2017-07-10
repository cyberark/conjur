---
title: Quick Tour
layout: page-no-toc
---


{% include toc.md key='introduction' %}
This document will use the Conjur command-line interface (CLI) to show you how to use Conjur to perform some common tasks, such as load policy data and secrets into Conjur, fetch secrets, login as a machine, fetch a secret while logged in as a machine, perform a permission check, and send Conjur commands using the raw HTTP (REST) API.


{% include toc.md key='docker' %}
* [Docker for Mac – v17.03](https://download.docker.com/mac/stable/16048/Docker.dmg) 
* [Docker for Windows](https://docs.docker.com/docker-for-windows/install/#download-docker-for-windows)


{% include toc.md key='cli' %}
You can easily download and run the Conjur CLI using the official pre-built images hosted by Docker Hub. 

{% highlight shell %}
  $ docker run -it conjurinc/cli5
{% endhighlight %}


{% include toc.md key='environment' %}
Use your Conjur account information to export your environment variables:

{% highlight shell %}
  $ export CONJUR_APPLIANCE_URL=http://conjur 
  $ export CONJUR_ACCOUNT=myorg 
  $ conjur authn login -u admin -p your-admin-api-key 
{% endhighlight %}


{% include toc.md key='login' %}
Once you have setup your server and CLI, make sure you are logged in as the `admin` user:

{% highlight shell %}
$ conjur authn whoami
{ "account": "mycorp", "user": "admin" }
{% endhighlight %}

With this accomplished, you're ready to walk through the following tour of Conjur features.

{% include toc.md key='policies' %}

In order to manage control of infrastructure, you use Conjur policies to create access rules between users, machines, services and secrets. Policies are the medium of security model collaboration. Since they are human readable, they can be shared with all stakeholders to gain consensus before commiting changes to your security infrastructure.

A policy is a declarative document (data, not code), so loading a policy cannot have any effect other than to create and update the role-based access control model inside the Conjur service. It is written using Policy Markup, a subset of YAML which is human-readable and thus homoiconic: it does what it looks like it does.

Documents in Policy Markup format are easy to generate and manipulate using any programming language, and they are idempotent so you can safely re-apply a policy any number of times. These properties make them automation-friendly.

Here is a typical policy file. Save this file as "conjur.yml":

{% include policy-file.md policy='tour' %}

Now map the policy document to your Docker container: 
{% highlight shell %}
  $ docker run -v /host/directory:/container/directory
{% endhighlight %}


{% include toc.md key='loading' %}

To load the policy, use the CLI command `conjur policy load <policy-id> <policy-file>`. This command requires two arguments:

* `policy-id` The first time you load a policy, use the policy id "root". This is a special policy name that is used to define root-level data. 
* `policy-file` Policy file containing statements in YAML format. 

{% highlight shell %}
$ conjur policy load root conjur.yml
Loaded policy 'root'
{
  "created_roles": {
    "myorg:user:alice": {
      "id": "myorg:user:alice",
      "api_key": "kme9412wxd05w32ask613anjk46yj11dq25ewed32hfqbzhkjec4w"
    },
    "myorg:host:myapp-01": {
      "id": "myorg:host:myapp-01",
      "api_key": "r9exkb2485qz62ka9jvz1c0f9w1q4re5h2g7m2wq2y9n5rc3m7hnzz"
    }
  },
  "version": 1
}
{% endhighlight %}

You created a user and a group, and added the user to the group. You also created a host, and added the host to a layer. And you also created some variables, which can be used to store and distribute secret data, then you granted some permissions on the variables. Other tutorials provide more explanation about these different objects, how they are created how permissions are managed.

The command response includes the following data:

* **created_roles** *Hash<role_id, api_key>* Conjur issues an API key to each new role which is created by the policy. These API keys are printed in the response. If you want to login as one of these roles, you can use the corresponding API key.

* **version** *integer* The server reported `"version": 1`, because this is the first version of the "root" policy that you have loaded. As you update the policy, the version number will be incremented. You can use the CLI to view the current and historical policy YAML.

{% include toc.md key='exploring' %}

Once the data is loaded into the server, you can use the command line to list all the objects:

{% highlight shell %}
$ conjur list -i
[
  "myorg:policy:root",
  "myorg:policy:db",
  "myorg:variable:db/password",
  "myorg:group:db/secrets-users",
  "myorg:policy:myapp",
  "myorg:layer:myapp",
  "myorg:host_factory:myapp",
  "myorg:group:developers",
  "myorg:user:alice",
  "myorg:host:myapp-01"
]
{% endhighlight %}

Or just the groups:

{% highlight shell %}
$ conjur list -i -k group
[
  "myorg:group:db/secrets-users",
  "myorg:group:developers"
]
{% endhighlight %}

Conjur makes it easy to store and retrieve encrypted data in variables. Initially, a variable is like an empty bucket, but it has important metadata and security rules. To show details about a variable (or any other object), use `conjur show`:

{% highlight shell %}
$ conjur show variable:db/password
{
  "created_at": "2017-06-07T19:58:36.118+00:00",
  "id": "myorg:variable:db/password",
  "owner": "myorg:policy:db",
  "policy": "myorg:policy:root",
  "permissions": [
    {
      "privilege": "read",
      "role": "myorg:group:db/secrets-users",
      "policy": "myorg:policy:root"
    },
    {
      "privilege": "execute",
      "role": "myorg:group:db/secrets-users",
      "policy": "myorg:policy:root"
    }
  ],
  "annotations": [

  ],
  "secrets": [

  ]
}
{% endhighlight %}

Objects like users, groups, hosts and layers are roles, which mean they can belong to other roles. A well-known example of this is when a user belongs to a group. To show the memberships of a role use `conjur role memberships`:

{% highlight shell %}
$ conjur role memberships host:myapp-01
[
  "myorg:host:myapp-01",
  "myorg:layer:myapp",
  "myorg:group:db/secrets-users"
]
{% endhighlight %}

{% include toc.md key='adding-secret' %}

The policy defines a variable called "db/password". As we mentioned earlier, Conjur variables store encrypted, access-controlled data. To load a secret value into the "db/password", use the following commands:

{% highlight shell %}
$ password=$(openssl rand -hex 12)
$ conjur variable values add db/password $password
Value added
{% endhighlight %}

{% include toc.md key='fetching-secret' %}

Here's how to retrieve a secret value:

{% highlight shell %}
$ conjur variable value db/password
fde5c4a45ce573f9768987cd
{% endhighlight %}

The most recent 20 values of each variable are retained in Conjur in case you need to retrieve them again. The version history is 1-based, so to retrieve the first historical version of a secret, use the `-v` option:

{% highlight shell %}
$ conjur variable value -v 1 db/password
fde5c4a45ce573f9768987cd
{% endhighlight %}

{% include toc.md key='machine-login' %}

So far, we have performed all the commands while logged in as the "admin" user. But, we showed how the server issued a new API key for the host "myapp-01". 

To login as another role, use the CLI command `conjur authn login`. When prompted for the password, enter the API key which was printed when you loaded the policy.

{% highlight shell %}
$ conjur authn login host/myapp-01
Please enter host/myapp-01's password (it will not be echoed):
Logged in
$ conjur authn whoami
{ "account": "mycorp", "user": "host/myapp-01" }
{% endhighlight %}

<div class="note">
<strong>Note</strong> If you've lost the API key of a host, you can reset it using the command <tt>conjur host rotate_api_key -h &lt;host-id&gt;</tt>.
</div>
<p/>

{% include toc.md key='fetching-as-machine' %}

Beacuse the policy permits the layer "myapp" to `execute` the variable "db/password", and because the host "myapp-01" is a member of this layer, we can now fetch the secret value while authenticated as the host:

{% highlight shell %}
$ conjur variable value db/password
fde5c4a45ce573f9768987cd
{% endhighlight %}



{% include toc.md key='next-steps' %}

Email <support@conjur.net> for access to Conjur Enterprise v4.9 to continue your explorations on prem.