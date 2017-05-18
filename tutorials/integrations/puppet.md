---
title: Tutorial - Puppet
layout: page
---

In conjunction with the [conjur Puppet module](https://forge.puppet.com/conjur/conjur),
Conjur provides a comprehensive secrets management solution for securely
distributing secrets through Puppet. Conjur + Puppet has clear advantages
over other approaches to secrets management such as hiera-eyaml and hiera-vault:

* Access to secrets is controlled separately for each node. 
* No "master key" is installed on the Puppet master; in fact, the Puppet master
does not hold any long-lived key to the secrets vault at all.
* Access to secrets is managed via machine identity and role-based access control policies, which are kept in source control.

As a result, the "blast radius" of a compromised node or Puppet master is minimized.
Only those secrets available to a node are revealed to an attacker. A compromise
of a backup of the master reveals no secrets at all.

## Demonstration

This demo assumes that you have a Puppet-managed environment available to you,
and that you have a working Conjur server and client.

1) Load the policies into Conjur.

[conjur-example](https://github.com/conjurinc/conjur-example/) is a simple way to get a good set of policies into Conjur.

From the Conjur client environment (`client` container or your local machine):

{% highlight shell %}
$ git clone git@github.com:conjurinc/conjur-example.git
$ cd conjur-example
$ conjur policy load bootstrap policies/conjur.yml
{% endhighlight %}

2) Load the secret data into Conjur.

Again, from your Conjur client environment (`client` container or your local machine),
use the CLI to generate a secret value and load it into Conjur:

{% highlight shell %}
$ password=$(openssl rand -hex 12)
$ echo password | conjur variable values add inventory-db/password
Value added
{% endhighlight %}

3) Generate a host factory token to enroll the Puppet-ized node

Again, from your Conjur client environment (`client` container or your local machine),
use the CLI to generate a host factory token for the `inventory` layer:

{% highlight shell %}
$ conjur hostfactory tokens create inventory
{
  "expiration": "a-timestamp",
  "cidr": [],
  "token": "3zt94bb200p69nanj64v9sdn1e15rjqqt12kf68x1d6gb7z33vfskx"
}    
{% endhighlight %}

4) Run a Puppet-ized node

Create a Puppet manifest which connects to Conjur and fetches the data.
For demo purposes, provide the host factory token directly in the `conjur`
class. 

{% highlight puppet %}
class { conjur:
  account         => 'mycompany',
  appliance_url   => 'http://conjur',
  authn_login     => 'host/inventory-01',
  host_factory_token => Sensitive('3zt94bb200p69nanj64v9sdn1e15rjqqt12kf68x1d6gb7z33vfskx')
}    
{% endhighlight %}

## Next steps

You've now been through the essential Conjur-Puppet workflow. 

As next steps, may we suggest:

* Review the [conjur Puppet module](https://forge.puppet.com/conjur/conjur) documentation
on Puppet Forge.
* Operationalize the host factory token by distributing it through a more 
secure means, such as AWS S3 + AWS IAM Instance Role.

 
