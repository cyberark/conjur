
{% include toc.md key='statement-reference' section='delete' %}

Explicitly deletes an object. This statement should only be used in `PATCH` mode. 

Note that if an object exists in the database when a policy `PUT` update is made which does not include that object, then the object is deleted.

This operation is a nop if the object does not exist.

#### Attributes

* **record** The object to be deleted.

#### Permission Required

`update` on the policy.

#### Example

Given the policy:

{% highlight yaml %}
- !group developers
{% endhighlight %}

The following policy update deletes the group:

{% highlight yaml %}
- !delete
  record: !group developers
{% endhighlight %}

