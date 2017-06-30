---
title: Quick Tour
layout: page
---

{% include toc.md key='prerequisites' %}

* A [Conjur server](/conjur/installation/server.html) endpoint.
* The [Conjur CLI](/conjur/installation/client.html).

{% include toc.md key='introduction' %}

This document will use the Conjur command-line interface (CLI) to show you how to use Conjur to perform some common tasks, such as load policy data and secrets into Conjur, fetch secrets, login as a machine, fetch a secret while logged in as a machine, perform a permission check, and send Conjur commands using the raw HTTP (REST) API.

{% include toc.md key='login' %}

Once you have setup your server and CLI, make sure you are logged in as the `admin` user:

{% include shell-command.md command='tour-login-whoami' %}

With this accomplished, you're ready to walk through the following tour of Conjur features.

{% include toc.md key='policies' %}

In order to manage control of infrastructure, you use Conjur policies to create access rules between users, machines, services and secrets. 

A policy is a declarative document - data, not code - so loading a policy cannot have any effect other than to create and update the role-based access control model inside the Conjur service. It is written using Policy Markup, a subset of YAML which is human-readable and thus homoiconic: it does what it looks like it does.

Documents in Policy Markup format are easy to generate and manipulate using any programming language, and they are idempotent so you can safely re-apply a policy any number of times. These properties make them automation-friendly.

Here is a typical policy file. Save this file as "conjur.yml":

{% include policy-file.md policy='tour' %}

Policies are the medium of security model collaboration. Since they are human readable, they can be shared with all stakeholders to gain consensus before commiting changes to your security infrastructure.

{% include toc.md key='loading' %}

To load the policy, use the CLI command `conjur policy load <policy-id> <policy-file>`. This command requires two arguments:

* `policy-id` The first time you load a policy, use the policy id "root". This is a special policy name that is used to define root-level data. 
* `policy-file` Policy file containing statements in YAML format. 

{% include shell-command.md command='tour-load-root-policy' %}

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

{% include toc.md key='permission-denied' %}

However, `update` privilege is required to write a new value into a variable, so if we try and do this while logged in as the host, it's not allowed:

{% highlight shell %}
$ conjur variable values add db/password $password
403 Forbidden
{% endhighlight %}

{% include toc.md key='permission-check-api' %}

The `conjur check` command can be determined to find out if a transaction is allowed:

{% highlight shell %}
$ conjur check variable:db/password execute
true
$ conjur check variable:db/password update
false
{% endhighlight %}

This permission checking capability can be used to implement custom access control, such as protecting web services from unauthorized users.

{% include toc.md key='programming' %}

Conjur is fully programmable via its HTTP ("REST") API, and with client libraries in various languages. 

The [API Reference](/reference/api.html) has full details on the API. Here are a couple of examples using cURL to give you a feel for it.

Before calling most API functions, you need to authenticate and obtain an access token. The route is `POST /authn/:account/:login/authenticate`, with the API key as the request body. Assuming the following shell variables:

* **CONJUR_APPLIANCE_URL** server URL
* **CONJUR_ACCOUNT** organization account name
* **api_key** API key of the user 

Authenticating as the `admin` user looks like this:

{% highlight shell %}
$ token=$(curl -X POST \
  -s \
  -k \
  --data $api_key \
  $CONJUR_APPLIANCE_URL/authn/$CONJUR_ACCOUNT/admin/authenticate)
{% endhighlight %}

<div class="note">
<strong>Note</strong> The option <tt>-k</tt> is used to disable certificate validation for HTTPS. This option is not used if you are running Conjur in a local sandbox and accessing via HTTP. If you are running Conjur with a self-signed certificate, use the <tt>--cacert</tt> option instead.
</div>
<p/>

If you examine the token, it's a JSON object:

{% highlight shell %}
$ echo $token
{"data":"admin","timestamp":"2017-06-08 14:31:23 UTC","signature":"DxzpFnx06MwLEkUBD_...OWGJjKAOIaYmkqPar","key":"be89767ed6a482101f40d429cf574b36"}
{% endhighlight %}

To use the token as an HTTP Authorization header, it needs to be encoded as Base64:

{% highlight shell %}
$ token_header=$(echo -n $token | base64 -w0)
$ echo $token_header
eyJkYXRhIjoiYWRtaW4iLCJ0aW1l
...
MTAxZjQwZDQyOWNmNTc0YjM2In0=
{% endhighlight %}

<div class="note">
<strong>Note</strong> The option <tt>-w0</tt> prevents line breaks from being added to the Base64 encoded string.
</div>
<p/>

With the token in this form, you can now call other Conjur REST API methods. For example, here's how to fetch a secret:

{% highlight shell %}
$ curl -H "Authorization: Token token=\"$token_header\"" \
  $CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/db/password
734b9714929e04ce2963a26d
{% endhighlight %}

The client API libraries make use of these techniques under the covers, and you can use this knowledge to write your own client code from scratch or to contribute an API client for a new language. 

{% include toc.md key='next-steps' %}

* Check out the [Conjur Tutorials](./tutorials/).

<script type="text/javascript">
  function extractShellCommand(shellBlock) {
    var blockLines = block.innerText.split("\n");
    var command = "";

    for(var j = 0; j < blockLines.length; j++) {
      var line = blockLines[j].trim();
      
      if(line.slice(-1) == "\\") {
        command += line.substring((j == 0 ? 2 : 0), line.length - 1);
      } else {
        command += line.substring((j == 0 ? 2 : 0), line.length);
        break;
      }
    }

    return command;
  }

  function createClipboardHoverButton(block, text) {
    var btn = document.createElement("button")
    block.parentNode.insertBefore(btn, block);

    btn.setAttribute("class", "hover-button");
    btn.setAttribute("data-clipboard-text", text);
    var clipboard = new Clipboard(btn);
  }

  var shellBlocks = document.getElementsByClassName("language-shell");

  for(var i = 0; i < shellBlocks.length; i++) {
    var block = shellBlocks[i];
    var command = extractShellCommand(block.innerText);

    createClipboardHoverButton(block, command);
  }
</script>
