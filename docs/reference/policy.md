---
title: Reference - Policies
layout: page
section: reference
description: Conjur Reference - Policies
---

{% include toc.md key='introduction' %}

Conjur is managed primarily through policies. A policy is a [YAML](https://en.wikipedia.org/wiki/YAML) document which describes users, groups, hosts, layers, web services, and variables, plus role-based access control grants and privileges. Once you've loaded a policy into Conjur, you can use the Conjur API to authenticate as a role, list and search the entities in the policy, perform permission checks, store and fetch secrets, etc.

Conjur's YAML syntax is easy for both humans and computers to read and write. Here's a typical policy which defines users, groups, and a policy for the application "myapp".

{% include policy-file.md policy='tour' %}

Some key features of this policy:

* There is 1 Variable (secret) which is a database password.
* There is one Host (a host is a job, container, server, or VM).
* The host belongs to a Layer.
* The Layer can read and execute (fetch), but not update the database secrets.
* A Host Factory can be used to dynamically create new hosts in the layer.
* Annotations help to explain the purpose of each statement in the policy.

{% include toc.md key='rbac' %}

Conjur implements role-based access control (RBAC) to provide role management and permission checking. In RBAC, a permission check is called a "transaction". Each transaction has three parts:

1. **the role** who, or what, is acting. In Conjur, individual entities such as users and hosts are roles, and groups-of-entities such as groups and layers are roles too.
2. **the privilege** the name of an action which the role is attempting to perform. In Conjur, privileges generally follow the Unix pattern of `read`, `execute` and `update`.
3. **the resource** the protected thing, such as a secret or a webservice.

RBAC determines whether a transaction is allowed or denied by traversing the roles and permissions in the policies. Transactions are always denied by default, and only allowed if the privilege is granted to some role (e.g. a Layer) of the current authenticated role (e.g. a Host).

In the example above, the `permit` statement in the "db" policy instructs Conjur RBAC to allow some transactions:

* role: `group:db/secrets-users`
* privilege: `read` and `execute`
* resource: all variables in the "db" policy

Permissions are also available via ownership. Each object in Conjur has an owner, and the owner always have full privileges on the object.

By default, when a policy is created, the policy is owned by the current authenticated user who is creating the policy. Objects inside a policy are owned by the policy (which is a kind of role), so the current authenticated user's ownership of the policy is transitive to all the objects in the policy.

{% include toc.md key='loading' %}

Conjur policies are loaded through the CLI using the command `conjur policy load`. This command requires two arguments:

* `policy-id` An identifier for the policy. The first time you load a policy, use the policy id "root". This is a special policy name that is used to define root-level data. The "root" policy may define sub-policies, initially empty, which you can later populate with their own data. Aside from the "root" policy, policy ids are not valid until the corresponding policy has been created.
* `policy-file` Policy file containing statements in YAML format. Use a single dash `-` to read the policy from STDIN.

Here's how to load the policy "conjur.yml":

{% highlight shell %}
$ conjur policy load root conjur.yml
Policy loaded
{% endhighlight %}

#### Multi-file Policies
It is natural to split up your policy into multiple files. For example, consider
the policy given in the [What is a Policy?](/reference/policy.html#what-is-a-policy)
section.

We could break this policy up into three files:

"db.yml":

{% include policy-file.md policy='tour-db' %}

"myapp.yml":

{% include policy-file.md policy='tour-myapp' %}

"entitlements.yml":

{% include policy-file.md policy='tour-entitlements' %}

Initially, we could load this set of files into the policy by calling
{% highlight shell %}
$ conjur policy load --replace root db.yml
Policy loaded
$ conjur policy load root myapp.yml
Policy loaded
$ conjur policy load root entitlements.yml
Policy loaded
{% endhighlight %}

Over time you may want to make changes to these files - for example, to update the entitlements to add or revoke privileges. When updates are made, we'll still need to reload all files associated with a given policy, even if only some have been modified. The easiest way to do this is to concatenate the associated files before reloading.  For example, if working in a Linux environment you would run:

{% highlight shell %}
$ cat db.yml myapp.yml entitlements.yml | conjur policy load --replace root -
Policy loaded
{% endhighlight %}

{% include toc.md key='history' %}

When you load a policy, the policy YAML is stored in the Conjur Server. As you make updates to the policy, the subsequent versions of policy YAML are stored as well. This policy history is available by fetching the `policy` resource. For example, using the CLI:

{% highlight shell %}
$ conjur show policy:frontend
{% endhighlight %}

{% include toc.md key='loading-modes' %}

The server supports three different modes for loading a policy : **POST**, **PATCH**, and **PUT**.

### POST Mode

In **POST** mode, the server will only create new data. If the policy contains deletion statements, such as `!delete`, `!revoke`, or `!deny`, it's an error.

If there are objects that already exist in the server but are not specified in the policy, those objects are left alone.

#### Permission Required

The client must have `create` privilege on the policy.

### PATCH Mode

In **PATCH** mode, the server will both create and delete data.

Objects and grants that already exist in the server but are not specified in the policy will be left alone.

#### Permission Required

The client must have `update` privilege on the policy.

### PUT Mode

In **PUT** mode, the data in the server will be replaced with the data specified in the policy.

Objects and grants that exist in the server but aren't specified in the policy will be deleted.

#### Permission Required

The client must have `update` privilege on the policy.

{% include toc.md key='delegation' %}

An API call which attempts to modify a policy requires `create` (for **POST**) or `update` (for **PUT** and **PATCH**) privilege on the affected policy.

These permission rules can be leveraged to delegate management of the Conjur policy system across many team members.

When a Conjur account is created, an empty "root" policy is created by default. This policy is owned by the `admin` user of the account. As the owner, the `admin` user has full permissions on the "root" policy.

A policy document can define policies within it. For example, if the "root" policy is:

{% include policy-file.md policy='policy-reference-root-example' %}

Then two new policies will be created: "db" and "frontend". The account "admin" user will own these policies as well, since no explicit owner was specified.

To delegate ownership of policies, create user groups and assign those groups as policy owners:

{% include policy-file.md policy='policy-reference-root-example-ownership' %}

Now the user groups you defined will have ownership (and full management privileges) over the corresponding policies. For example, a member of "frontend-developers" will be able to make any change to the "frontend" policy, but will be forbidden from modifying the "root" and "db" policies.

`!permit` statements can also be used to manage policy permissions in a more granular way. Here's how to allow a user group to `read` and `create`, but not `update`, a policy:

{% include policy-file.md policy='policy-reference-root-example-permissions' %}

With this policy, the "frontend-developers" group will be allowed to **GET** and **POST** the policy, but not to **PUT** or **PATCH** it.

{% include toc.md key='statement-reference' %}

This section describes in detail the syntax of the policy YAML.

### Common attributes

Some attributes are common across multiple entities:

* **id** An identifier which is unique to the kind of entity (`user`, `host`, `variable`, etc). By convention, Conjur ids are path-based. For example: `prod/webservers`. Each record in Conjur is uniquely identified by `account:kind:id`.
* **owner** A role having all privileges on the thing it's applied to. For example, if a role `group:frontend` is the owner of a secret, then the group and all of its members can perform any action on the secret. Normally, the `owner` attribute is only needed in the root policy.

{% include_relative _delete.md %}
{% include_relative _deny.md %}
{% include_relative _entitlements.md %}
{% include_relative _grant.md %}
{% include_relative _group.md %}
{% include_relative _host.md %}
{% include_relative _layer.md %}
{% include_relative _permit.md %}
{% include_relative _policy.md %}
{% include_relative _revoke.md %}
{% include_relative _user.md %}
{% include_relative _variable.md %}
{% include_relative _webservice.md %}
