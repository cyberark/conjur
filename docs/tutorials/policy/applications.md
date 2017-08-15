---
title: Tutorial - Enrolling an Application
layout: page
section: tutorials
---

{% include toc.md key='introduction' %}

A very common question is: how do I add new secrets and apps to my infrastructure?

At Conjur, we refer to this process of adding new stuff as "enrollment". The basic flow works in four steps:

1. Define protected resources, such as Webservices and Variables, using a policy. Call this "Policy A".
2. In "Policy A", create a group which has access to the protected resources.
3. Define an application, generally consisting of a Layer (group of hosts), in another policy. Call this "Policy B".
4. In "Policy A", add the Layer from "Policy B" to a group which has access to the protected resources.

Step (4) has a special name, "entitlement", because in this step existing objects are linked together, and no new objects are created. An entitlement is always one of the following:

* Grant a policy Group to a Layer.
* Grant a policy Group to a different Group (usually a group of Users).

Organizing policy management into three categories - protected resources, applications, and entitlements - helps to keep the workflow organized and clear. It also satisfies the essential security requirements of separation of duties and least privilege.

* **Separation of duties** Management of protected resources is separated from management of client applications. Different teams can be responsible for each of these tasks. In addition, policy management can also be delegated to machine roles if desired.
* **Least privilege** The client applications are granted exactly the privileges that they need to perform their work. And policy managers (whether humans or machines) have management privileges only on the objects that rightfully belong under their control.

{% include toc.md key='prerequisites' %}

* A [Conjur server](/installation/server.html) endpoint.
* The [Conjur CLI](/installation/client.html).

{% include toc.md key='setup' %}

We will model a simple application in which a `frontend` service connects to a `db` server. The `db` policy defines a `password`, which the `frontend` application uses to log in to the database.

Here is a skeleton policy for this scenario, which simply defines two empty policies: `db` and `frontend`. Save this policy as "conjur.yml":

{% include policy-file.md policy='application_root' %}

Then load it using the following command:

{% highlight shell %}
$ conjur policy load --replace root conjur.yml
Loaded policy 'root'
{
  "created_roles": {
  },
  "version": 2
}
{% endhighlight %}

Use the `conjur list` command to view all the objects in the system:

{% highlight shell %}
$ conjur list
[
  "myorg:policy:root",
  "myorg:policy:db",
  "myorg:policy:frontend"
]
{% endhighlight %}

{% include toc.md key='define-resources' %}

Having defined the policy framework, we can load the specific data for the database.

Create the following file as "db.yml":

{% include policy-file.md policy='application_db' %}

Now load it using the following command:

{% highlight shell %}
$ conjur policy load db db.yml
Loaded policy 'db'
{
  "created_roles": {
  },
  "version": 1
}
{% endhighlight %}

The variable `db/password` has been created, but it doesn't contain any data. So the next step is to load the password value:

{% include db-password.md %}

{% include toc.md key='define-application' %}

For this example, the "frontend" policy will simply define a Layer and a Host. Create the following file as "frontend.yml":

{% include policy-file.md policy='application_frontend' %}

<div class="note">
<strong>Note</strong> Statically defining the hosts in a policy is appropriate for fairly static infrastructure. More dynamic systems such as auto-scaling groups and containerized deployments can be managed with Conjur as well. The details of these topics are covered elsewhere.
</div>
<p/>

Now load the frontend policy using the following command:

{% highlight shell %}
$ conjur policy load frontend frontend.yml
Loaded policy 'frontend'
{
  "created_roles": {
    "dev:host:frontend/frontend-01": {
      "id": "dev:host:frontend/frontend-01",
      "api_key": "1wgv7h2pw1vta2a7dnzk370ger03nnakkq33sex2a1jmbbnz3h8cye9"
    }
  },
  "version": 1
}
{% endhighlight %}

<div class="note">
<strong>Note</strong> The <tt>api_key</tt> printed above is a unique securely random string for each host. When you load the policy, you'll see a different API key. Be sure and use this API key in the examples below, instead of the value shown in this tutorial.
</div>
<p/>

{% include toc.md key='entitlement' %}

With the preceding steps completed, we now have the following objects and permissions in place:

* `variable:db/password` is created and populated with a value.
* `group:db/secrets-users` can "read" and "execute" the database password.
* `layer:frontend` is created, and `host:frontend/frontend-01` exists and belongs to the layer. We have an API key for it, so we can authenticate as this host.

When a frontend application is deployed to `host:frontend/frontend-01`, it can authenticate with the `api_key` printed above and attempt to fetch the db password. You can simulate this using the following CLI command:

{% highlight shell %}
$ CONJUR_AUTHN_LOGIN=host/frontend/frontend-01 \
  CONJUR_AUTHN_API_KEY=1wgv7h2pw1vta2a7dnzk370ger03nnakkq33sex2a1jmbbnz3h8cye9 \
  conjur variable value db/password
error: 403 Forbidden
{% endhighlight %}

Is the "error: 403 Forbidden" a mistake? No, it's demonstrating that the host is able to authenticate, but it's not permitted to fetch the secret.

What's needed is an **entitlement** to grant `group:db/secrets-users` to `layer:frontend`. You can verify that this role grant does not yet exist by listing the members of the role `group:db/secrets-users`:

{% highlight shell %}
$ conjur role members group:db/secrets-users
[
  "dev:policy:db"
]
{% endhighlight %}

And by listing the role memberships of the host:

{% highlight shell %}
$ conjur role memberships host:frontend/frontend-01
[
  "keg:host:frontend/frontend-01",
  "keg:layer:frontend"
]
{% endhighlight %}

Add the role grant by updating policy "db.yml" to the following:

{% include policy-file.md policy='application_entitlement' %}

Then load it using the CLI:

{% highlight shell %}
$ conjur policy load db db.yml
Loaded policy 'db'
{
  "created_roles": {
  },
  "version": 2
}
{% endhighlight %}

Now you can verify that the policy has taken effect. We will look at this in several different ways. First, verify that `layer:frontend` has been granted the role `group:db/secrets-users`:

{% highlight shell %}
$ conjur role members group:db/secrets-users
[
  "dev:policy:db",
  "dev:layer:frontend"
]
{% endhighlight %}

And, you can see that the `host:frontend/frontend-01` has `execute` privilege on `variable:db/password`:

{% highlight shell %}
$ conjur resource permitted_roles variable:db/password execute
[
  "dev:host:frontend/frontend-01",
  "dev:group:db/secrets-users",
  "dev:policy:frontend",
  "dev:policy:db",
  "dev:layer:frontend",
  "dev:user:admin"
]
{% endhighlight %}

The important line here is **dev:host:frontend/frontend-01**.

Now we can finish the tutorial by fetching the password while authenticated as the host:

{% highlight shell %}
$ CONJUR_AUTHN_LOGIN=host/frontend/frontend-01 \
  CONJUR_AUTHN_API_KEY=1wgv7h2pw1vta2a7dnzk370ger03nnakkq33sex2a1jmbbnz3h8cye9 \
  conjur variable value db/password
926c6e5622889763c9490ca3 <- Password printed here
{% endhighlight %}

Success! The host has the necessary (and minimal) set of privileges it needs to fetch the database password.

{% include toc.md key='next-steps' %}

This pattern can be extended in the following ways:

* Add more variables to the `db` policy
* Add more hosts to the `frontend` policy
* Automatically enroll hosts into the `frontend` layer by adding a Host Factory.
* Add more applications that need access to the database password, and grant them access by adding entitlements to the `db` policy.
* Create user groups such as `database-administrators` and `frontend-developers`, and give them management rights on their respective policies. In this way, policy management can be federated and scaled.
