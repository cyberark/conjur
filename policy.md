---
title: Policy Guide
layout: page
---

## Groups

`security_admin` is the customary top-level group. Other common groups are `operations` and `developers`.

{% highlight yaml %}
- !group security_admin

- !group operations
  owner: !group security_admin

- !group developers
  owner: !group security_admin
{% endhighlight %}

## Users

Here's how to create two users named `kevin` and `bob`. SSH public keys for Kevin and Bob are created here as well, and the users are assigned to groups.

{% highlight yaml %}
- !user
  id: kevin
  public_keys:
  - ssh-rsa AAAAB3NzaC1yc2HRjpbdyUG08c+2VR7E+10trhK5Pt kgilpin@laptop

- !user
  id: bob
  public_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAABAAABAQDP2Kr5QzRlHAa6/s bob@laptop

- !grant
  role: !group security_admin
  member: !member
    role: !user kevin
    admin: true

- !grant
  role: !group operations
  member: !user bob
{% endhighlight %}

## Applications

Consider a simple infrastructure is composed of two layers: the database, and the application.

The database has a password, which can be accessed by the application.

{% highlight yaml %}
- !policy
  id: database
  body:
  - !variable password

  - !layer
{% endhighlight %}

{% highlight yaml %}
- !policy
  id: app
  body:
  - &variables
    - !variable ssl/private_key
    - !variable ssl/certificate
  
  - !layer

  - !permit
    role: !layer
    privileges: [ read, execute ]
    resources: *variables
{% endhighlight %}

## Hosts

Specific host machines are defined and placed into their corresponding layers:

{% highlight yaml %}
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

## Entitlements

Add entitlements which allow the following:

* `app` layer can fetch the database password.
* `operations` group has SSH admin access to the database and app layers

{% highlight yaml %}
- !permit
  role: !layer prod/app
  privileges: [ read, execute ]
  resource: !variable prod/database/password
  
- !grant
  roles:
  - !automatic-role
    record: !layer prod/database
    role_name: admin_host
  - !automatic-role
    record: !layer prod/app
    role_name: admin_host
  member: !group operations
{% endhighlight %}

## Putting it together

Combine the policies together into a top-level Conjurfile:

{% highlight yaml %}
- include: groups.yml
- include: users.yml
- !policy
  id: prod
  body:
  - include: policies/db.yml
  - include: policies/app.yml
- !include hosts.yml
- !include entitlements.yml
{% endhighlight %}
