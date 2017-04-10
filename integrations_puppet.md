---
title: Integration - Puppet
layout: page
sidebar_class: item-sub
index: 31
---

In conjunction with the [conjur Puppet module](https://forge.puppet.com/conjur/conjur),
Possum provides a comprehensive secrets management solution for securely
distributing secrets through Puppet. Possum + Puppet has clear advantages
over other approaches to secrets management such as hiera-eyaml and hiera-vault:

* Access to secrets is controlled separately for each node. 
* No "master key" is installed on the Puppet master; in fact, the Puppet master
does not hold any long-lived key to the secrets vault at all.
* Access to secrets is managed via machine identity and role-based access control policies, which are kept in source control.

As a result, the "blast radius" of a compromised node or Puppet master is minimized.
Only those secrets available to a node are revealed to an attacker. A compromise
of a backup of the master reveals no secrets at all.

## Demonstration

1) Get Puppet

This demo assumes that you have a Puppet-managed environment available to you.
If you don't, you can quickly build a Puppet master using [Puppet-in-Docker](https://github.com/puppetlabs/puppet-in-docker),
 or by [downloading open-source Puppet](https://puppet.com/download-open-source-puppet).

2) Get Possum

**Via Docker**

docker-compose is a quick and easy way to get Possum running in a local
environment. 

{% highlight shell %}
$ git clone git@github.com/conjurinc/possum.git
$ cd possum/demo
$ docker-compose up -d
$ docker-compose exec client bash
{% endhighlight %}

**Via AWS**

* Search AWS Marketplace for "Possum".
* Launch an ec2 instance from the AMI.
* SSH to the instance.
* Download the Conjur CLI.
* Connect to Possum:

    `$ conjur init -h ec2-yourhostname.amazonaws.com`

3) Load the policies into Possum.

[possum-example](https://github.com/conjurinc/possum-example/) is a simple way to get a good set of policies into Possum.

From the Possum client environment (`client` container or your local machine):

{% highlight shell %}
$ git clone git@github.com:conjurinc/possum-example.git
$ cd possum-example
$ possum policy load bootstrap policies/conjur.yml
{% endhighlight %}

4) Load the secret data into Possum.

Again, from your Possum client environment (`client` container or your local machine),
use the CLI to generate a secret value and load it into Possum:

{% highlight shell %}
$ password=$(openssl rand -hex 12)
$ echo password | possum variable values add inventory-db/password
Value added
{% endhighlight %}

5) Generate a host factory token to enroll the Puppet-ized node

Again, from your Possum client environment (`client` container or your local machine),
use the CLI to generate a host factory token for the `inventory` layer:

{% highlight shell %}
$ conjur hostfactory tokens create inventory
{
  "expiration": "a-timestamp",
  "cidr": [],
  "token": "3zt94bb200p69nanj64v9sdn1e15rjqqt12kf68x1d6gb7z33vfskx"
}    
{% endhighlight %}

6) Run a Puppet-ized node

Create a Puppet manifest which connects to Possum and fetches the data.
For demo purposes, provide the host factory token directly in the `conjur`
class. 

{% highlight puppet %}
class { conjur:
  account         => 'mycompany',
  appliance_url   => 'http://possum',
  authn_login     => 'host/inventory-01',
  host_factory_token => Sensitive('3zt94bb200p69nanj64v9sdn1e15rjqqt12kf68x1d6gb7z33vfskx')
}    
{% endhighlight %}

## Next steps

You've now been through the essential Possum-Puppet workflow. 

As next steps, may we suggest:

* Review the [conjur Puppet module](https://forge.puppet.com/conjur/conjur) documentation
on Puppet Forge.
* Operationalize the host factory token by distributing it through a more 
secure means, such as AWS S3 + AWS IAM Instance Role.

 
