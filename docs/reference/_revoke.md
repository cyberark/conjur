
{% include toc.md key='statement-reference' section='revoke' %}

Explicitly revokes a role grant. This statement should only be used in `PATCH` mode. 

Note that if a role grant exists in the database when a policy `PUT` update is made which does not include that role grant, then the grant is revoked.

This operation is a nop if the role grant does not exist.

#### Attributes

* **member** The role from which the `role` will be revoked.
* **role** The role which has been granted.

#### Permission Required

`update` on the policy.

#### Example

Given the policy:

{% highlight yaml %}
- !group developers
- !group employees
- !grant
  role: !group employees
  member: !group developers
{% endhighlight %}

The following policy update revokes the grant:

{% highlight yaml %}
- !revoke
  role: !group employees
  member: !group developers
{% endhighlight %}

