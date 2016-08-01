---
title: Policy Guide
layout: page
index: 10
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

A group of users and other groups.

When a user becomes a member of a group they are granted the group role, and inherit the group’s privileges. Group members can be added with or without “admin option”. With admin option, the member can add and remove members to/from the group.

Groups can also be members of groups; in this way, groups can be organized and nested in a hierarchy.

`security_admin` is the customary top-level group.

### Example

{% highlight yaml %}
- !user alice
- !user bob

- !group
  id: ops

- !grant
    role: !group ops
    members:
    - !user alice
    - !member
        role: !user bob
        admin: true
{% endhighlight %}

### User

A human user.

Note For servers, VMs, scripts, PaaS applications, and other code actors, create Hosts instead of Users.

#### Attributes

* **public_keys** Stores public keys for the user, which can be retrieved through the public keys API.

### Example

{% highlight yaml %}
- !user
  id: kevin
  public_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAAD...+10trhK5Pt kgilpin@laptop

- !user
  id: bob
  public_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAAD...DP2Kr5QzRl bob@laptop

- !grant
  role: !group security_admin
  member: !member
    role: !user kevin
    admin: true

- !grant
  role: !group operations
  member: !user bob
{% endhighlight %}

# Servers, Apps, Containers and Code

This section uses a simple example. It's an infrastructure which is composed of two layers: an application layer and a database layer.

The database has a password, which can be accessed by the application.

## Host

{% include policy-element.md element=site.data.policy.host %}

## Layer

Host are organized into sets called "layers" (sometimes known in some other systems as "host groups"). Layers map 
logically to the groups of machines and code in your infrastructure. For example, a group of servers or VMs can be a layer; 
a cluster of containers which are performing the same function (e.g. running the same image) can also be modeled as a layer. 
A script which is deployed to a server can be a layer. And an application which is deployed to a PaaS can also be a layer.

Using layers to model the privileges of code helps to separate the permissions from the physical implementation of the 
application. For example, if an application is migrated from a PaaS to a container cluster, the logical layers that compose the application (web servers, app servers, database tier, cache, message queue) can remain the same.

### Example

{% highlight yaml %}
- !layer prod/database

- !layer prod/app

- !group operations

- !host db-01
- !host app-01
- !host app-02

- !grant
  role: !layer prod/database
  member: !host db-01

- !grant
  role: !layer prod/app
  members:
  - !host app-01
  - !host app-02
{% endhighlight %}

# Other records

## Variable

{% include policy-element.md element=site.data.policy.variable %}

## Webservice

{% include policy-element.md element=site.data.policy.webservice %}

# Entitlements

Entitlements are role grants and privilege grants which create permissions relationships between records. 

## Grant

Grant one role to another. When role A is granted to role B, then role B is said to “have” role A. The 
set of all memberships of role B will include A. The set of direct members of role A will include role B.

If the role is granted with `admin` option, then the grantee (role B), in addition to having the role, can 
also grant and revoke the role to other roles.

The only limitation on role grants is that there cannot be any cycles in the role graph. For example, if role 
A is granted to role B, then role B cannot be granted to role A.

Users, groups, hosts, and layers can all behave as roles, which means they can be granted to and revoked 
from each other. For example, when a Group is granted to a User, the User gains all the privileges of the 
Group. (Note: “Adding” a User to a Group is just another way to say that the Group role is granted to the User).

### Example

{% highlight yaml %}
- !user alice
  owner: !group security_admin

- !group operations
  owner: !group security_admin
    
- !group development
  owner: !group security_admin
  
- !group everyone
  owner: !group security_admin

- !grant
  role: !group operations
  member: !member
    role: !user alice
    admin: true

- !grant
  role: !group ops
  member: !group development

- !grant
  role: !group everyone
  member: !group development
  member: !group operations
{% endhighlight %}


## Permit

{% include policy-element.md element=site.data.policy.permit %}

# Policy

{% include policy-element.md element=site.data.policy.policy %}

# Nesting policies with `!include`

Individual policy files can be combined together into a top-level Conjurfile using the `!include` directive. If `!include` is used from within the body of a policy, the included policy statements are owned by the policy role, and namespaced by the policy id. Otherwise, they are simply evaluated
at the global scope.

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
