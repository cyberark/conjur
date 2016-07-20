---
title: Possum - Documentation - Policy Guide
layout: doc
---

# What is a Possum policy?

In order to describe and control your infrastructure, you'll create a set of authoritative documents describing users, groups, hosts, layers, web services, variables. The generic name for these things is Possum "records".

In addition to defining the records, the policy also includes role-based access control grants and privileges, which control how system actors such as users and hosts are allowed to interact with protected resources such as variables, hosts and web services.

For the purposes described above, Possum provides a Policy Markup language. Policy Markup is written in [YAML](http://yaml.org) which is human-readable, and also easy to generate and manipulate using any programming language.

# Role-based access control

Permissions are defined in Possum using Role-Based Access Control (RBAC). The fundamental operation in RBAC is a "transaction", which includes three parts:

* **role** the subject; who, or what, is acting. In Possum, identities such as users and hosts, plus groups-of-identities such as groups and layers, are roles.
* **privilege** the name of an action which the role is attempting to perform. In Possum, privileges generally follow the Unix pattern of `read`, `execute` and `updated`. However, any name can be used as a privilege.
* **resource** the object being acted upon. A resource is something you want to protect; in Possum, every record is also a resource.

In RBAC, each "transaction" is either permitted or denied. Transactions are always denied by default.

One role (the "grantor") can be "granted" to another (the "grantee"), in which case the grantee gains the privileges of the grantor. For example, when a group role is granted to a user, the user gains all the privileges of the group. "Adding a user to a group" is the same as granting the group role to the user.

For a detailed description of RBAC, see the [Overview of RBAC in Conjur](https://developer.conjur.net/key_concepts/rbac.html).

# Policy reference

## Common attributes

Possum records share the following attributes:

* **account** Records in Possum can be divided into separate accounts. Each record in Possum is uniquely identified by `account:kind:id`.
* **kind** `kind` is normally implicit in the policy document. For example, the `kind` of each User record is `user`. Possum can be extended with custom resources, which should specify the `kind` explicitly. In addition, some Possum records create `internal` roles, which can be identified by the presence of the `@` symbol in their `kind`. 
* **id** an identifier which is unique within the `account:kind` namespace. By convention, Possum ids are path-based. For example: `prod/webservers`. An exception is host ids, which may use the path-based convention, but may also use the DNS naming convention `www-01.mycorp.com`. Keep in mind that ids may not be re-used across hosts, so the ids of dynamically provisioned hosts should be constructed uniquely.
* **owner** The owner of a record is able to fully administer the record. For example, if a group is the owner of a host, then the group role (and all of its transitive role member), have full permissions on the host, and can also grant and revoke the host role.

## People

### Group

{% include policy-element.md element=site.data.policy.group %}

### User

{% include policy-element.md element=site.data.policy.user %}

# Servers, Apps, Containers and Code

This section uses a simple example. It's an infrastructure which is composed of two layers: an application layer and a database layer.

The database has a password, which can be accessed by the application.

## Host

{% include policy-element.md element=site.data.policy.host %}

## Layer

{% include policy-element.md element=site.data.policy.layer %}

# Other records

## Variable

{% include policy-element.md element=site.data.policy.variable %}

## Webservice

{% include policy-element.md element=site.data.policy.webservice %}

# Entitlements

Entitlements are role grants and privilege grants which create permissions relationships between records. 

## Grant

{% include policy-element.md element=site.data.policy.grant %}

## Permit

{% include policy-element.md element=site.data.policy.permit %}

# Policy

{% include policy-element.md element=site.data.policy.policy %}

# Putting it together

Individual policy files can be combined together into a top-level Conjurfile using the `!include` directive. If `!include` is used from within the body of a policy, the included policy statements are owned by the policy role, and namespaced by the policy id.

{% highlight yaml %}
- !include groups.yml
- !include users.yml
- !policy
  id: prod
  body:
  - !include policies/db.yml
  - !include policies/app.yml
- !include hosts.yml
- !include entitlements.yml
{% endhighlight %}
