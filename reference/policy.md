---
title: Reference - Policies
layout: page
---

{% include toc.md key='prerequisites' %}

TODO

{% include toc.md key='introduction' %}

Conjur is managed primarily through policies. A policy is a [YAML](http://yaml.org) document which describes users, groups, hosts, layers, web services, and variables, plus role-based access control grants and privileges. Once you've loaded a policy into Conjur, you can use the Conjur API to authenticate as a role, list and search the entities in the policy, and perform permission checks (more on all this later). 

Conjur's YAML syntax is easy for both humans and computers to read and write. Here's a typical policy which defines users, groups, and a policy for the application "myapp". 

Save this policy as "conjur.yml":

{% highlight yaml %}
# conjur.yml
- !policy
  id: myapp
  body:
  - &variables
    - !variable ssl-cert
    - !variable ssl-key
  
  - !layer
    annotations:
      description: My application layer

  - !permit
    resource: *variables
    privileges: [ read, execute ]
    roles: !layer

- !host myapp-01

- !grant
  role: !layer myapp
  member: !host myapp-01
{% endhighlight %}

Some key features of this policy:

* There are 2 variables (secrets) which the application can use.
* The hosts (containers, servers, or VMs) will have the `layer` role.
* The `layer` role can read and execute (fetch), but not update the secrets.
* Annotations help to explain the purpose of each statement in the policy.

{% include toc.md key='rbac' %}

Conjur implements role-based access control (RBAC) to provide permission checks. In RBAC, a permission check is called a "transaction". Each transaction has three parts:

1. **the role** who, or what, is acting. In Conjur, individual entities such as users and hosts are roles, and groups-of-entities such as groups and layers are roles too.
2. **the privilege** the name of an action which the role is attempting to perform. In Conjur, privileges generally follow the Unix pattern of `read`, `execute` and `update`. 
3. **the resource** the protected thing, such as a secret or a webservice.

RBAC determines whether a transaction is allowed or denied by traversing the roles and permissions in the policies. (Transactions are always denied by default).

In the example above, the `permit` statements at the bottom of the policy instruct Conjur RBAC to allow some transactions:

* role: `layer`
* privilege: `read` and `execute`
* resource: all variables in the policy

{% include toc.md key='loading' %}

Conjur policies are loaded through the CLI using the command `conjur policy load`. This command requires two arguments:

* `policy-id` An identifier for the policy. The first time you load a policy, use the policy id "bootstrap". This is a special policy name that is used to define root-level data. The "bootstrap" policy may define sub-policies, initially empty, which you can later populate with their own data. Until a policy id has been created by the bootstrap policy, it's not valid.
* `policy-file` Policy file containing statements in YAML format. Use a single dash `-` to read the policy from STDIN.

Here's how to load the policy "conjur.yml":

{% highlight shell %}
$ conjur policy load bootstrap conjur.yml
Policy loaded
TODO: Show additional command output
{% endhighlight %}

The server supports various behaviors for loading a policy. 

Note that when you loaded the policy, the server indicated the number of versions of this policy. 

{% include toc.md key='versions' %}

TODO: Describe policy versions

{% include toc.md key='loading-modes' %}

The server supports various behaviors for loading a policy. 

{% include toc.md key='delegation' %}

TODO: The content below was copy-pasted from another section, but needs to be rewritten.

To demonstrate how delegation works, we will login as frank, who belongs to the frontend group. Enter Frank’s API key at the login prompt.

{% highlight shell %}
$ conjur login
Enter your username to log into Conjur: frank@people
Enter the password: ******
$ conjur whoami
demo:user:frank@people
{% endhighlight %}

Then Frank can load `prod/frontend` policy:

{% highlight shell %}
$ cat frontend.yml | conjur policy:load prod/frontend -
Loaded policy version 1
Created 2 roles

Id                                   API Key
-----------------------------------  -----------------------------------------------------
demo:host:prod/frontend/frontend-01  b57k1j2vb5pnx2rkpjvt5jkbbc1j13t38236c38esn6pak1f0yb28
demo:host:prod/frontend/frontend-02  3p2aryd3rdk2m816jysdk3n2se3wmpy1s23954hvckmfsgcbkpsjw
{% endhighlight %}


Load the database policy:

{% highlight shell %}
$ cat database.yml | conjur policy:load prod/database -
Error 403: Forbidden
{% endhighlight %}

Whoops! We are still logged in as Frank, and Frank doesn't have permission to manage the prod/database policy. This is Conjur's RBAC in action. 

To fix the problem, login as `owen`, who belongs to the operations group. Enter Owen's API key at the login prompt.

{% highlight shell %}
$ conjur login
Enter your username to log into Conjur: owen@people
Enter the password: ******
{% endhighlight %}

Then Owen can load `prod/database` policy:

Because Owen owns the `prod/database` policy, he has full management over the objects in it. This means that he can also load a new value into the `password` variable. Use `openssl` to generate a new random string, and store it in the password:

{% include toc.md key='delegation' %}

{% include toc.md key='statement-reference' %}

This section will describe in detail the syntax of the policy YAML.

### Common attributes

Some attributes are common across multiple entities:

* **id** An identifier which is unique to the kind of entity (`user`, `host`, `variable`, etc). By convention, Conjur ids are path-based. For example: `prod/webservers`. Each record in Conjur is uniquely identified by `account:kind:id`.
* **owner** A role having all privileges on the thing it's applied to. For example, if a role `group:frontend` is the owner of a secret, then the group and all of its members can perform any action on the secret. Normally, the `owner` attribute is only needed in the bootstrap policy.

{% include toc.md key='statement-reference' section='policy' %}

A policy is used to organize a common set of records and permissions grants into a common namespace (`id` prefix).

The `body` element of a policy lists the entities and grants that are part of the policy. Each entity in the policy inherits the id of the policy; for example, a variable named `db-password` in a policy named `prod/myapp` would have a fully-qualified id `prod/myapp/db-password`. In addition, all the entities in the body of the policy are owned by the policy. Therefore, the owner of a policy implicitly owns everything defined in the policy. This nested ownership makes it possible to delegate the management of a complex system to many different teams and groups, each with responsibility over a small set of policies. 

#### Example

{% highlight yaml %}
- !policy
  id: prod
  body:
  - !policy
    id: webserver
    body:
    - &secrets
      - !variable ssl/private-key

    - !layer

    - !grant
      role: !layer
      permissions: [ read, execute ]
      resources: *secrets
{% endhighlight %}

{% include toc.md key='statement-reference' section='user' %}

A human user. For servers, VMs, scripts, PaaS applications, and other code actors, create hosts instead of users.

Users can authenticate using their `id` as the login and their API key as the credential. When a new user is created, it's assigned a randomly generated API key. The API key can be reset (rotated) by an administrative user if it is lost or compromised. 

Users can also be assigned a password. A user can use her password to `login` and obtain her API key, which can be used to authenticate as described above. Further details on login and authentication are provided in the API documentation.

#### Attributes

* **id** Should not contain special characters such as `:/`. It may contain the `@` symbol.
* **public_keys** Stores public keys for the user, which can be retrieved through the public keys API.

#### Example

{% highlight yaml %}
- !user
  id: kevin
  public_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAAD...+10trhK5Pt kgilpin@laptop

- !group
  id: ops

- !grant
  role: !group ops
  member: !user kevin
{% endhighlight %}

{% include toc.md key='statement-reference' section='group' %}

A group of users and other groups. Layers can also be added to groups, in order to give applications the privileges of the group (such as access to secrets).

When a user becomes a member of a group they are granted the group role, and inherit the group’s privileges. Groups can also be members of groups; in this way, groups can be organized and nested in a hierarchy.

#### Attributes

* **id**

#### Example

{% highlight yaml %}
- !user alice

- !user bob

- !group
  id: everyone
  annotations:
    description: All users belong to this group.

- !group
  id: ops
  annotations:
    description: This group is for production operational personnel.

- !grant
    role: !group ops
    members:
    - !user alice
    - !user bob
    
- !grant
    role: !group everyone
    member: !group ops
{% endhighlight %}

{% include toc.md key='statement-reference' section='host' %}

A server, VM, script, job, or container, or any other type of coded or automated actor.

Hosts defined in a policy are generally long-lasting hosts, and assigned to a
layer through a `!grant` entitlement. Assignment to layers is the primary way
for hosts to get privileges, such as access to variables.

Hosts can authenticate using `host/<id>` as the login and their API key as the credential. When a new host is created, it's assigned a randomly generated API key. The API key can be reset (rotated) by an administrative user if it is lost or compromised. 

#### Attributes

* **id**

#### Example

{% highlight yaml %}
- !layer webservers

- !host
  id: www-01
  annotations:
    description: Hypertext web server
        
- !grant
  role: !layer webservers
  member: !host www-01
{% endhighlight %}

{% include toc.md key='statement-reference' section='layer' %}

Host are organized into roles called "layers" (sometimes known in some other systems as "host groups"). Layers map logically to the groups of machines and code in your infrastructure. For example, a group of servers or VMs can be a layer; a cluster of containers which are performing the same function (e.g. running the same image) can also be modeled as a layer; a script which is deployed to a server can be a layer; an application which is deployed to a PaaS can also be a layer. Layers can be used to organize your system into broad permission groups, such as `dev`, `ci`, and `prod`, and for granular organization such as `dev/frontend` and `prod/database`.

Using layers to model the privileges of code helps to separate the permissions from the physical implementation of the application. For example, if an application is migrated from a PaaS to a container cluster, the logical layers that compose the application (web servers, app servers, database tier, cache, message queue) can remain the same. Also, layers are not tied to a physical location. If an application is deployed to multiple clouds or data centers, all the servers, containers and VMs can belong to the same layer.

#### Example

{% highlight yaml %}
- !layer prod/database

- !layer prod/app

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

{% include toc.md key='statement-reference' section='variable' %}

A variable provides encrypted, access-controlled storage and retrieval of arbitrary data values. Variable values are also versioned. The last 20 historical versions of the variable are available through the API; the latest version is returned by default.

Values are encrypted using aes-256-gcm. The encryption used in Conjur has been independently verified by a professional, paid cryptographic auditor.

#### Attributes

* **id**
* **kind** (string) Assigns a descriptive kind to the variable, such as 'password' or 'SSL private key'.
* **mime_type** (string) The expected MIME type of the values. This attribute is used to set the Content-Type header on HTTP responses.

#### Privileges

* **read** Permission to view the variable's metadata (e.g. annotations).
* **execute** Permission to fetch the default value or any historical value.
* **update** Permission to add a new value.

Note that `read`, `execute` and `update` are separate privileges. Having `execute` privilege does not confer `read`; nor does `update` confer `execute`.

#### Example

{% highlight yaml %}
- &variables
  - !variable
    id: db-password
    kind: password

  - !variable
    id: ssl/private_key
    kind: SSL private key
    mime_type: application/x-pem-file

- !layer app

- !permit
  role: !layer app
  privileges: [ read, execute ]
  resources: *variables
{% endhighlight %}

{% include toc.md key='statement-reference' section='webservice' %}

Represents a web service endpoint, typically an HTTP(S) service.

Permission grants are straightforward: an input HTTP request path is mapped to a webservice resource id. The HTTP method is mapped to an RBAC privilege. A permission check is performed, according to the following transaction:

* **role** client role on the HTTP request. The client can be obtained from an Authorization header (e.g. signed access token), or from the subject name of an SSL client certificate.
* **privilege** typically `read` for read-only HTTP methods, and `update` for POST, PUT and PATCH.
* **resource** web service resource id

#### Example

{% highlight yaml %}
- !group analysts

- !webservice
  id: analytics

- !permit
  role: !group analysts
  privilege: read
  resource: !webservice analytics
{% endhighlight %}

{% include toc.md key='statement-reference' section='entitlements' %}

Entitlements are role and privilege grants. `grant` is used to grant a `role` to a `member`. `permit` is used to give a `privilege` on a `role` to a resource.

Entitlements provide the "glue" between policies, creating permission relationships between different roles and subsystems. For example, a policy for an application may define a `secrets-managers` group which can administer the secrets in the policy. An entitlement will grant the policy-specific `secrets-managers` group to a global organizational group such as `operations` or `people/teams/frontend`.

{% include toc.md key='statement-reference' section='grant' %}

Grants one role to another. When role A is granted to role B, then role B is said to "have" role A. The set of all memberships of role B will include A. The set of direct members of role A will include role B.

If the role is granted with `admin` option, then the grantee (role B), in addition to having the role, can also grant and revoke the role to other roles.

A limitation on role grants is that there cannot be any cycles in the role graph. For example, if role A is granted to role B, then role B cannot be granted to role A.

Users, groups, hosts, and layers are roles, which means they can be granted to and revoked from each other.

#### Example

{% highlight yaml %}
- !user alice

- !group operations
    
- !group development
  
- !group everyone

- !grant
  role: !group operations
  member: !user alice

- !grant
  role: !group ops
  member: !group development

- !grant
  role: !group everyone
  member: !group development
  member: !group operations
{% endhighlight %}

{% include toc.md key='statement-reference' section='permit' %}

Give privileges on a resource to a role.

Once a privilege is given, permission checks performed by the role will return `true`.

Note that permissions are not "inherited" by resource ids. For example, if a role has `read` privilege on a variable called `db`, that role does not automatically get `read` privilege on `variable:db/password`. In RBAC, inheritance of privileges only happens through role grants. RBAC is explicit in this way to avoid unintendend side-effects from the way that resources are named.

#### Example

{% highlight yaml %}
- !layer prod/app
        
- !variable prod/database/password
        
- !permit
  role: !layer prod/app
  privileges: [ read, execute ]
  resource: !variable prod/database/password
{% endhighlight %}

{% include toc.md key='statement-reference' section='include' %}

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
