---
title: Ansible Integration
layout: page
section: integrations
description: Conjur Integrations - Ansible Role
---

## What is Ansible?
Ansible is an automation language and automation engine that lets you describe end-to-end IT application environments w/ a “playbook.” Ansible’s simple, human-readable language allows orchestration of your application lifecycle no matter where it’s deployed.


{% include toc.md key='integration' %}

The [Conjur Ansible integration](https://github.com/cyberark/ansible-role-conjur)
can be used to configure a host with a Conjur machine identity. Through
integration with Conjur, the machine can be granted least-privilege
access to retrieve the secrets it needs in a secure manner. This approach
reduces the administrative power of the Ansible host and prevents it from
becoming a high value target. Conjur integration also provides additional
benefits, including storing security policy as code, and simplified secret rotation.

### "configure-conjur-identity" Role
The Conjur role provides a method to “Conjurize” or configure a host with a Conjur Machine Identity using Ansible.


### "retrieve_conjur_variable" lookup plugin
Conjur's retrieve_conjur_variable lookup plugin provides a means for retrieving secrets from Conjur for use in playbooks. Note that as lookup plugins run in the Ansible host machine, the identity that will be used for retrieving secrets are those of the Ansible host. Thus, the Ansible host requires god like privilege, essentially execute access to every secret that a remote node may need.

The lookup plugin can be invoked in the playbook's scope as well as in a task's scope.


### "summon_conjur" module
The Conjur Module provides a mechanism for using a remote node’s identity to retrieve secrets that have been explicitly granted to it. As Ansible modules run in the remote host, the identity used for retrieving secrets is that of the remote host. This approach reduces the administrative power of the Ansible host and prevents it from becoming a high value target.

Moving secret retrieval to the node provides a maximum level of security. This approach reduces the security risk by providing each node with the minimal amount of privilege required for that node. The Conjur Module also provides host level audit logging of secret retrieval. Environment variables are never written to disk.

The module receives variables and a command as arguments and, similar to [Conjur's Summon CLI](https://conjur.org/tools/summon.html), provides an interface for fetching secrets from a provider and exporting them to a sub-process environment.

Note that you can provide both Conjur variables and non-Conjur variables, where in Conjur variables a `!var` prefix is required.


{% include toc.md key='machineidentity' %}

As humans we are used to identity being applied to us, and also to static objects around us, but applying identity to dynamic, short-lived computing resources like containers is difficult, and therefore not as common, but without a machine identity system, applying security becomes human-bound and therefore almost impossible to automate.

Establishing identities for machines allows you to build a chain of trust, granting least amount of privilege (to secrets, services, etc.), while being able to audit everything.


{% include toc.md key='workflow' %}

- [Install Ansible](https://www.ansible.com/get-started)
- Define access with a Conjur policy using declarative format (YAML)
- Leverage the scaling power of RBAC (Role Based Access Control)
- Collaborate and peer review your policies (just like code)
- Store policies in version control for history and auditability
- Apply identity to remote hosts using Host Factory Tokens
- Update Playbooks to leverage identity to retrieve secrets and credentials
- Win

See the [Conjur Ansible Role GitHub repo](https://github.com/cyberark/ansible-role-conjur)
for integration instructions and a discussion of the security tradeoffs involved
in the potential integration approaches.
