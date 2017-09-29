---
title: Puppet Integration
layout: page
section: integrations
description: Conjur Integrations - Puppet Module
---

## What is Puppet?
[Puppet](https://puppet.com) helps you describe machine configurations in a
declarative language, bring machines to a desired state, and keep them there through automation.
Systems can be configured with Puppet either in a client/server architecture, using the Puppet
agent and Puppet master applications, or in a stand-alone architecture, using the Puppet apply
application.

{% include toc.md key='integration' %}

The [Conjur Puppet Module](https://forge.puppet.com/conjur/conjur) simplifies
the operations of establishing [Conjur](https://www.conjur.org) host identity
and allows authorized Puppet nodes to fetch secrets from Conjur.
Integration with Conjur provides a number of additional benefits,
including security policy as code andautomatic secret rotation.

- Puppet Forge: [forge.puppet.com/conjur/conjur](https://forge.puppet.com/conjur/conjur)
- GitHub: [github.com/cyberark/conjur-puppet](https://github.com/cyberark/conjur-puppet)

See the module page on Puppet Forge or README.md on GitHub for complete documentation.

### Establishing machine identity

In most cases we recommend bootstrapping Conjur machine identities with
[Host Factory tokens](/api.html#host-factory).
Nodes inherit the permissions of the layer for which the Host Factory token was generated.
Machine identity can also be bootstrapped before Puppet runs, when a machine is created.

To apply machine identity with this module, set variables `authn_login` and
`host_factory_token`.
Do not set the variable `authn_api_key` when using `host_factory_token`; it is not required.
`authn_login` should have a host/ prefix; the part after the slash will be used as the
node’s name in Conjur.

```
class { conjur:
  account            => 'mycompany',
  appliance_url      => 'https://conjur.mycompany.com/',
  authn_login        => 'host/redis001',
  host_factory_token => Sensitive('3zt94bb200p69nanj64v9sdn1e15rjqqt12kf68x1d6gb7z33vfskx'),
  ssl_certificate    => file('/etc/conjur.pem')
  version            => 5,
}
```

By default, all nodes using this Puppet module to bootstrap identity with `host_factory_token`
will have the following annotation set: `puppet: true`.

### Retrieving secrets

The module provides a `conjur::secret` function that can be used to retrieve secrets from
Conjur.
Given a Conjur variable identifier, `conjur::secret` uses the node’s Conjur identity to resolve
and return the variable’s value.

```
$dbpass = conjur::secret('production/postgres/password')
```

Hiera attributes can also be used to inform which secret should be fetched, depending on the
node running the Conjur module.
For example, if `hiera('domain')` returns "app1.example.com" and a Conjur variable
named `domains/app1.example.com/ssl-cert exists`,
the SSL certificate can be retrieved and written to a file like so:

```
file { '/etc/ssl/cert.pem':
  content   => conjur::secret("domains/%{hiera('domain')}/ssl-cert"),
  ensure    => file
  show_diff => false # only required for Puppet < 4.6
  # diff will automatically get redacted in 4.6 if content is Sensitive
}
```

{% include toc.md key='workflow' %}

- [Install Puppet](https://docs.puppet.com/puppet/latest/install_pre.html)
- Define access with a Conjur policy using declarative format (YAML) to leverage the scaling power of RBAC (Role Based Access Control)
- Collaborate and peer review your policies (just like code)
- Store policies in version control for history and auditability
- Apply identity to remote hosts using Host Factory tokens
- Update your own Puppet manifests to leverage Conjur identity to retrieve credentials, as shown above

See the [Conjur Puppet module GitHub repo](https://github.com/cyberark/conjur-puppet)
for complete integration instructions.
The [examples directory](https://github.com/cyberark/conjur-puppet/tree/master/examples)
shows the module in use in several different scenarios.
