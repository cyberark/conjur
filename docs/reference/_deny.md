{% include toc.md key='statement-reference' section='deny' %}

Explicitly revokes a permission grant. This statement should only be used in `PATCH` mode. 

Note that if a permission grant exists in the database when a policy `PUT` update is made which does not include that permission grant grant, then the grant is revoked.

This operation is a nop if the permission grant does not exist.

#### Attributes

* **resource** The resource on which the privilege is granted.
* **privilege** The privilege which will be revoked.
* **role** The role from which the `privilege` (or privileges) will be revoked.

#### Permission Required

`update` on the policy.

#### Example

Given the policy:

{% highlight yaml %}
  - !variable db/password
  - !host host-01
  - !permit
    resource: !variable db/password
    privileges: [ read, execute, update ]
    role: !host host-01
{% endhighlight %}

The following policy update revokes the `update` privilege:

{% highlight yaml %}
- !deny
  resource: !variable db/password
  privilege: update
  role: !host host-01
{% endhighlight %}

