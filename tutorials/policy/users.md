---
title: Tutorial - Managing Users and Groups
layout: page
---

{% include bootstrap_policy.html %}

## Add some users and groups

The next step is to add some human users and groups. You can do this by creating a policy file `people.yml` and loading it as the `people` policy. It this file, create two new groups `operations` and `frontend` and two users `owen` and `frank`, and places them into the corresponding groups.

This is a typical example of how Possum policy management works: the *bootstrap* policy defines the overall policy structure, and then individual policies are loaded into the slots defined by the bootstrap policy.

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

**Note** For a detailed description of Possum RBAC, see the [Overview of RBAC in Conjur](https://developer.conjur.net/key_concepts/rbac.html).

Once you've defined the policy, you can use the `possum` command line to load it. The API keys of the new users are printed in the response; these can be used to authenticate as the corresponding user. 

{% highlight shell %}
$ cat people.yml | possum policy:load people -
Loaded policy version 1
Created 2 roles

Id                      API Key
----------------------  ------------------------------------------------------
demo:user:frank@people  3wetc8236tw70vchjjqtqh60y1k38762y898ge2j15nappp52r
demo:user:owen@people   1mebxfvz6c3jy30q44bp32g0dbc2gf3crrekhwe720sa8vg22ccg5y
{% endhighlight %}

If you lose the API key of a user, you can reset (rotate) it using the `admin` account. But for this demo, just leave the API keys in the console so that you can use them later.

Now you can use the `possum` tool to list the new groups and users:

{% highlight shell %}
$ possum list -k group
Id                               Owner                  Policy
-------------------------------  ---------------------  ------------------------
demo:group:security_admin     demo:user:admin     demo:policy:bootstrap
demo:group:people/operations  demo:policy:people  demo:policy:people
demo:group:people/frontend    demo:policy:people  demo:policy:people

$ possum list -k user
Id                         Owner                  Policy
-------------------------  ---------------------  ---------------------
demo:user:people/owen   demo:policy:people  demo:policy:people
demo:user:people/frank  demo:policy:people  demo:policy:people
{% endhighlight %}


