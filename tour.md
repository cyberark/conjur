---
title: Quick Tour
layout: page
---

{% include toc.md key='prerequisites' %}

* A [Conjur server](/conjur/installation/server.html) endpoint.
* The [Conjur CLI](/conjur/installation/client.html).

{% include toc.md key='login' %}

Once you have setup your server and CLI, make sure you are logged in as the `admin` user:

{% highlight shell %}
$ conjur authn whoami
{ "account": "mycorp", "user": "admin" }
{% endhighlight %}

With this accomplished, you're ready to walk through the following tour of Conjur features.

{% include toc.md key='introduction' %}

In order to manage control of infrastructure, you use Conjur policies to create access rules between users, machines, services and secrets. 

A policy is a declarative document - data, not code - so loading a policy cannot have any effect other than to create and update the role-based access control model inside your Conjur appliance. It is written using Policy Markup, a subset of YAML which is human-readable and thus homoiconic: it does what it looks like it does.

Documents in Policy Markup format are easy to generate and manipulate using any programming language, and they are idempotent so you can safely re-apply a policy any number of times. These properties make them automation-friendly.

Here is a typical policy file. Save this file as "conjur.yml":

{% include policy-file.md policy='tour' %}

Policies are the medium of security model collaboration. Since they are human readable, they can be shared with all stakeholders to gain consensus before commiting changes to your security infrastructure.

{% include toc.md key='loading' %}

You can use the CLI command `conjur policy load <policy-id> <policy-file>` to load your policy. This command requires two arguments:

* `policy-id` The first time you load a policy, use the policy id "bootstrap". This is a special policy name that is used to define root-level data. 
* `policy-file` Policy file containing statements in YAML format. Use `-` to read the policy from stdin.

{% highlight shell %}
$ conjur policy load bootstrap conjur.yml
Loaded policy 'bootstrap'
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

You created users and groups, and granted group roles to users to make them members of groups. You also created a host, and added the host to a layer. And you also created some variables, which can be used to store and distribute secret data, and you granted some permissions on the variables. Other tutorials provide more explanation about these different objects, how they are created and the permissions management works. 

The response indicates the following:

* **created_roles** For each new role which was created by the policy, the server creates an API key. These API keys are printed in the response. If you want to login as one of these roles, you can use the corresponding API key.

* **version** The server reported `"version": 1`, because this is the first version of the "bootstrap" policy that you have loaded. As you update the policy, the version number will be incremented. You can use the server API to fetch historical versions of the policy.

{% include toc.md key='exploring' %}

Once the data is loaded into the server, you can use the command line to list all the objects:

{% highlight shell %}
$ conjur group -i
TODO: provide response
{% endhighlight %}

Or just the groups:

{% highlight shell %}
$ conjur group -i -k group
TODO: provide response
{% endhighlight %}

Or to show details about a variable:

{% highlight shell %}
$ conjur show variable:db/password
TODO: provide response
{% endhighlight %}

Or to show the memberships of a role:

{% highlight shell %}
$ conjur role memberships host:myapp-01
TODO: provide response
{% endhighlight %}

{% include toc.md key='adding-secret' %}

{% highlight shell %}
$ password=$(openssl rand -hex 12)
$ conjur variable values add db/password $password
Value added
{% endhighlight %}

{% include toc.md key='fetching-secret' %}

{% highlight shell %}
$ conjur variable value db/password
fde5c4a45ce573f9768987cd
{% endhighlight %}

{% include toc.md key='machine-login' %}

When prompted for the password, enter the host API key which was printed when you loaded the policy.

{% highlight shell %}
$ conjur authn login host/myapp-01
$ conjur authn whoami
{ "account": "mycorp", "user": "host/myapp-01" }
{% endhighlight %}

{% include toc.md key='fetching-as-machine' %}

{% highlight shell %}
$ conjur variable value db/password
fde5c4a45ce573f9768987cd
{% endhighlight %}

{% include toc.md key='permission-denied' %}

{% highlight shell %}
$ password=$(openssl rand -hex 12)
$ conjur variable values add db/password $password
403 Forbidden
{% endhighlight %}

{% include toc.md key='permission-check-api' %}

TODO:

{% include toc.md key='next-steps' %}

* Check out the [Conjur Tutorials](./tutorials).

