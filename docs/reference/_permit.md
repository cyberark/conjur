
{% include toc.md key='statement-reference' section='permit' %}

Give privileges on a resource to a role.

Once a privilege is given, permission checks performed by the role will return `true`.

Note that permissions are not "inherited" by resource ids. For example, if a role has `read` privilege on a variable called `db`, that role does not automatically get `read` privilege on `variable:db/password`. In RBAC, inheritance of privileges only happens through role grants. RBAC is explicit in this way to avoid unintendend side-effects from the way that resources are named.

The `resource` must be defined in the same policy as the `!permit`. The `role` can be defined in any policy.

#### Example

{% highlight yaml %}
- !layer prod/app
        
- !variable prod/database/password
        
- !permit
  role: !layer prod/app
  privileges: [ read, execute ]
  resource: !variable prod/database/password
{% endhighlight %}

