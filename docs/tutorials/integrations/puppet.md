---
title: Tutorial - Puppet
layout: page
---

{% include toc.md key='introduction' %}

The [conjur Puppet module](https://forge.puppet.com/conjur/conjur) provides a comprehensive solution for managing machine identity and distributing secrets through Puppet. Conjur + Puppet has clear advantages over other approaches to secrets management such as hiera-eyaml and hiera-vault:

* Access to secrets is controlled separately for each node.
* No "master key" is installed on the Puppet master; in fact, the Puppet master
does not hold any long-lived key to the secrets vault at all.
* Access to secrets is managed via machine identity and role-based access control policies, which are kept in source control.

As a result, the "blast radius" of a compromised node or Puppet master is minimized. Only those secrets available to a node are revealed to an attacker. A stolen backup of the Puppet master reveals no secrets at all.

{% include toc.md key='prerequisites' %}

* A [Conjur server](/installation/server.html) endpoint.
* The [Conjur CLI](/installation/client.html).
* A client machine with the Puppet agent installed.

{% include toc.md key='overview' %}

When we run Puppet, the manifest will perform the following steps:

* Configure the client node's connection to Conjur.
* Assign an identity to the client node.
* Authenticate the node with Conjur.
* Fetch the database password from Conjur and merge this into a template file.
* Store the file on the client node.

The `conjur-conjur` module provides supporting functions for these operations.

{% include toc.md key='policy' %}

As with all Conjur workflows, we begin by defining the policies.

Save this file as "conjur.yml":

{% include policy-file.md policy='puppet' %}

It defines:

* `variable:db/password` Contains the database password.
* `layer:myapp` A layer (group of hosts) with access to the password.
* `host_factory:myapp` Used to create individual hosts and enroll them into `layer:myapp`.

Load the policy using the following command:

{% highlight shell %}
$ conjur policy load --replace root conjur.yml
Loaded policy 'root'
{
  "created_roles": {
    "dev:host:myapp-01": {
      "id": "dev:host:myapp-01",
      "api_key": "1wgv7h2pw1vta2a7dnzk370ger03nnakkq33sex2a1jmbbnz3h8cye9"
    }
  },
  "version": 1
}
{% endhighlight %}

{% include toc.md key='load-secret' %}

Next, we need to populate the database password with a secret value. Use the CLI to verify that the variable exists in Conjur:

{% highlight shell %}
$ conjur list -k variable
[
  "dev:variable:db/password"
]
{% endhighlight %}

Now, use OpenSSL to generate a random secret, and load it into the variable:

{% include db-password.md %}

{% include toc.md key='host-factory-token' %}

In the introduction, we mentioned that the Puppet manifest assigns a Conjur identity to the client node. For this purpose, we use the Conjur Host Factory.

Create a host factory token for use by Puppet:

{% highlight shell %}
$ conjur hostfactory tokens create myapp
[
  {
    "token": "1axrq3g2cybym19qkhrc2z5kd5j3btcmwy3fyxngh22rvxrw1jh7d32",
    "expiration": "2017-05-24T14:13:20+00:00",
    "cidr": [

    ]
  }
]
{% endhighlight %}

The `token` that you see above can be used to enroll machines into the "myapp" layer.

{% include toc.md key='manifest' %}

Now it's time to build the Puppet manifest. The manifest needs to do two things:

1. Configure the connection to Conjur.
2. Assign the machine identity.

For the first task, we supply the appropriate values for `account` and `appliance_url`. For the second, we use the host factory token. The manifest uses the host factory token to create a Conjur host called "myapp-01" which belongs to the `myapp` layer. Then it uses the privileges granted to the host by layer membership to fetch the database password.

Create the following Puppet manifest:

{% highlight puppet %}
class { conjur:
  account         => 'dev',
  appliance_url   => 'http://conjur',
  authn_login     => 'host/myapp-01',
  host_factory_token => Sensitive('1axrq3g2cybym19qkhrc2z5kd5j3btcmwy3fyxngh22rvxrw1jh7d32')
}    

file { '/tmp/dbpass':
  ensure    => file,
  content   => conjur::secret('db/password'),
  show_diff => false,  # don't log file content!
}
{% endhighlight %}

{% include toc.md key='conjur-module' %}

For the manifest to work, you need to install the `conjur-conjur` Puppet module:

{% highlight shell %}
$ puppet module install conjur-conjur
Notice: Preparing to install into /etc/puppetlabs/code/environments/production/modules ...
Notice: Downloading from https://forgeapi.puppet.com ...
Notice: Installing -- do not interrupt ...
/etc/puppetlabs/code/environments/production/modules
└── conjur-conjur (v2.0.0)
{% endhighlight %}

{% include toc.md key='run-puppet' %}

Now, run Puppet:

{% highlight shell %}
$ puppet apply manifest.pp
...
TODO: show output
{% endhighlight %}

TODO: success message
