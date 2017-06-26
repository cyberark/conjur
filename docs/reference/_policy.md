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

