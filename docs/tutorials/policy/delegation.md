---
title: Tutorial - Delegating Policy Management
layout: page
section: tutorials
---

{% include toc.md key='introduction' %}

For small teams, it's fine for two or three people to have "admin" access to Conjur and perform all the policy management.

But when Conjur is used in a large organization, it's important that the security administrators be able to delegate management of Conjur to experienced members of other teams. In this way, the security team doesn't get overwhelmed by change requests to Conjur. In addition, as operating Conjur becomes a wider organizational concern, better discussions will occur within the organization about how to use it most effectively.

{% include toc.md key='prerequisites' %}

* A [Conjur server](/installation/server.html) endpoint.
* The [Conjur CLI](/installation/client.html).

It's advisable, but not required, to step through the [Enrolling an Application](./applications.html) tutorial before this one.

{% include toc.md key='setup' %}

Most Conjur deployments will begin with a small number of users working as administrators, loading all the policy data. All the policies can be kept in a single source control repository. Let's set up a simple example of this.

First, a top-level policy defines two empty policies: `db` and `frontend`. Save this policy as "conjur.yml":

{% include policy-file.md policy='application_root' %}

Then create the following file as "db.yml":

{% include policy-file.md policy='application_db' %}

And "frontend.yml":

{% include policy-file.md policy='delegation_frontend' %}

Finally, load all the policies using the CLI:

{% highlight shell %}
$ conjur policy load --replace root conjur.yml
...
$ conjur policy load --replace db db.yml
...
$ conjur policy load --replace frontend frontend.yml
...
{% endhighlight %}

Then as a sanity check, list all the objects in the system:

{% highlight shell %}
$ conjur list
[
  "myorg:policy:root",
  "myorg:policy:db",
  "myorg:policy:frontend",
  "myorg:variable:db/password",
  "myorg:group:db/secrets-users",
  "myorg:layer:frontend"
]
{% endhighlight %}

{% include toc.md key='multi-user-concepts' %}

So far, we've run all commands as the account "admin" user. This is fine for small environments, but as the system grows bigger we would like to enable other trusted users to manage the security configuration and secret data of their own applications.

To do this, we start by creating more User and Group objects in Conjur. Once there are Groups in the system, we can start changing the ownership of policies.

Default policy ownership works like this:

1. If the policy doesn't have a parent (it's defined in a top-level policy file), then it's owned by the user who created the policy.
2. If the policy is created within another policy, it's owned by the containing policy.

So, following rule (1), our policies "db" and "frontend" are owned by the account "admin" user. You can verify this using the CLI:

{% highlight shell %}
$ conjur show policy:db | jq -r .owner
myorg:user:admin
{% endhighlight %}

<div class="note">
<strong>Note</strong> <a href="https://stedolan.github.io/jq/">jq</a> is a command-line tool to select data from JSON objects. Here we are selecting the <tt>owner</tt> field from the full JSON response from <tt>conjur show</tt>. The option <tt>-r</tt> requests "raw" (unquoted) output.
</div>
<p/>

Ownership of any object can be changed by using the `owner` field in policy YAML. For example:

{% highlight yaml %}
- !policy
  id: db
  owner: !group dba
{% endhighlight %}

Ownership of the "db" policy is assigned to the role "group:dba".

Now any role which has the role "group:dba" can fully manage the "db" policy. Policy owners can do all of the following:

* Create, update, and delete objects in the policy.
* Fully manage all objects in the policy, including variables and host factories.
* Grant privileges on policy objects to other roles (e.g. application layers).

So what does it mean to be "in the policy"? Each object and annotation has a `policy` attribute which indicates which policy that data belongs to. When you create an object, the `policy` attribute is set to the policy that created the data.

<div class="note">
<strong>Note</strong> The <tt>policy</tt> attribute is a little different than resource ownership. The <tt>policy</tt> attribute is used when a policy is being loaded to determine which data the policy update is allowed to effect.
</div>
<p/>

You can use the CLI to find out which policy an object is in. For example, the object "policy:db" is in the "root" policy, whereas the object "variable:db/password" is in the "db" policy:

{% highlight shell %}
$ conjur show policy:db | jq -r .policy
myorg:policy:root
$ conjur show variable:db/password | jq -r .policy
myorg:policy:db
{% endhighlight %}

If you try and modify or delete an object from the wrong policy, the object is not affected. One way to think about this is that during policy loading, the object primary key (unique identifier) is composed of **both** the object's `id` and the object's `policy`. So, during policy loading, two object references using the same `id` but different `policy` are not equivalent; therefore an attempt to modify an object from the wrong policy is either and error or is ignored.

{% include toc.md key='delegate' %}

To see this in action, let's add some users and groups to the policy "conjur.yml":

{% include policy-file.md policy='delegation-root-2' %}

Update the root policy:

{% highlight shell %}
$ conjur policy load --replace root conjur.yml
Loaded policy 'root'
{
  "created_roles": {
    ...
  },
  "version": 2
}
{% endhighlight %}

Save the API keys for "frank" and "donna" in shell variables:

{% highlight shell %}
$ api_key_donna=$(conjur user rotate_api_key -u donna)
$ api_key_frank=$(conjur user rotate_api_key -u frank)
$ echo $api_key_donna
1x9nd001x527x43zjqc1q3g07x7j3sh72jr2hws7p3qmrmz726k6htn
$ echo $api_key_frank
30qxjpj49tkc32ayf1mb2v3nycw25k3bvn1vfgvct2f0bcpqq1veqc
{% endhighlight %}

Now the following CLI command will attempt to update the "db" policy while authenticated as "donna":

{% highlight shell %}
$ CONJUR_AUTHN_LOGIN=donna CONJUR_AUTHN_API_KEY=$api_key_donna conjur policy load --replace db db.yml
error: 403 Forbidden
{% endhighlight %}

This is not a bug! We've created the users and groups, but we haven't changed the ownership of the policies.

Update the `owner` fields in "conjur.yml":

{% include policy-file.md policy='delegation-root-3' %}

Then update the root policy again:

{% highlight shell %}
$ conjur policy load --replace root conjur.yml
Loaded policy 'root'
{
  "created_roles": {
    ...
  },
  "version": 2
}
{% endhighlight %}

Now the the "db" policy can be updated while authenticated as "donna":

{% highlight shell %}
$ CONJUR_AUTHN_LOGIN=donna CONJUR_AUTHN_API_KEY=$api_key_donna conjur policy load --replace db db.yml
Loaded policy 'db'
{
  "created_roles": {
  },
  "version": 6
}
{% endhighlight %}

{% include toc.md key='summary' %}

In this tutorial, we showed how to assign the `owner` attribute of a policy to a group. The owner of a policy has full privileges on the objects in the policy, and we showed how a user can be permitted to manage her own policy.

In this way, users can be empowered to manage their own machines, variables, and web services without weakening the security of the overall system.

This type of delegated / federated workflow can allow for superior velocity in a development organization, without compromising on security and compliance controls.
