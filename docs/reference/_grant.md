{% include toc.md key='statement-reference' section='grant' %}

Grants one role to another. When role A is granted to role B, then role B is said to "have" role A. The set of all memberships of role B will include A. The set of direct members of role A will include role B.

If the role is granted with `admin` option, then the grantee (role B), in addition to having the role, can also grant and revoke the role to other roles.

A limitation on role grants is that there cannot be any cycles in the role graph. For example, if role A is granted to role B, then role B cannot be granted to role A.

Users, groups, hosts, and layers are roles, which means they can be granted to and revoked from each other.

The `role` must be defined in the same policy as the `!grant`. The `member` can be defined in any policy.

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

