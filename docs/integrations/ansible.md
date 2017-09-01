---
title: Conjur Ansible Role
layout: page
section: integrations
---

The [Conjur Ansible Role](https://github.com/cyberark/ansible-role-conjur)
can be used to configure a host with a Conjur machine identity. Through
integration with Conjur, the machine can then be granted least-privilege
access to retrieve the secrets it needs in a secure manner. This approach
reduces the administrative power of the Ansible host and prevents it from
becoming a high value target. Conjur integration also provides additional
benefits, including storing security policy as code, an audit trail, and
simplified secret rotation.

{% include toc.md key='integration' %}

See the [Conjur Ansible Role GitHub repo](https://github.com/cyberark/ansible-role-conjur)
for integration instructions and a discussion of the security tradeoffs involved
in the potential integration approaches.
