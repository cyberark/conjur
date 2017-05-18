---
title: Tutorial - Managing Users and Groups
layout: page
---

{% include bootstrap_policy.html %}

## Create users and groups

The next step is to add some human users and groups. You can do this by creating a policy file `people.yml` and loading it as the `people` policy. It this file, create two new groups `operations` and `frontend` and two users `owen` and `frank`, and places them into the corresponding groups.

This is a typical example of how Conjur policy management works: the *bootstrap* policy defines the overall policy structure, and then individual policies are loaded into the slots defined by the bootstrap policy.

{% highlight yaml %}
# people.yml
- !group operations

- !group frontend

- !user owen

- !user frank

- !grant
  role: !group operations
  member: !user owen

- !grant
  role: !group frontend
  member: !user frank
{% endhighlight %}

The `group` and `user` statements are self-explanatory - they create new objects. The `grant` statement is a role-based access control operation; when role *A* is granted to role *B*, role *B* is said to "have" role *A*. All permissions held by role *A* are inherited by role *B*, so if role *A* can perform some operation, then role *B* can perform it as well.

Once you've defined the policy, you can use the `conjur` command line to load it. The API keys of the new users are printed in the response; these can be used to authenticate as the corresponding user. 

{% highlight shell %}
$ conjur policy load bootstrap people.yml
... TODO: show output
{% endhighlight %}

If you lose the API key of a user, you can reset (rotate) it using the `admin` account. But for this demo, just leave the API keys in the console so that you can use them later.

Now you can use the `conjur` tool to list the new groups and users:

{% highlight shell %}
$ conjur list -k group -i
TODO: Proper group output

$ conjur list -k user -i
TODO: Proper user output
{% endhighlight %}


