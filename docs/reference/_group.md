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
