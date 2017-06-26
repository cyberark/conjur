
{% include toc.md key='statement-reference' section='layer' %}

Host are organized into roles called "layers" (sometimes known in some other systems as "host groups"). Layers map logically to the groups of machines and code in your infrastructure. For example, a group of servers or VMs can be a layer; a cluster of containers which are performing the same function (e.g. running the same image) can also be modeled as a layer; a script which is deployed to a server can be a layer; an application which is deployed to a PaaS can also be a layer. Layers can be used to organize your system into broad permission groups, such as `dev`, `ci`, and `prod`, and for granular organization such as `dev/frontend` and `prod/database`.

Using layers to model the privileges of code helps to separate the permissions from the physical implementation of the application. For example, if an application is migrated from a PaaS to a container cluster, the logical layers that compose the application (web servers, app servers, database tier, cache, message queue) can remain the same. Also, layers are not tied to a physical location. If an application is deployed to multiple clouds or data centers, all the servers, containers and VMs can belong to the same layer.

#### Example

{% highlight yaml %}
- !layer prod/database

- !layer prod/app

- !host db-01
- !host app-01
- !host app-02

- !grant
  role: !layer prod/database
  member: !host db-01

- !grant
  role: !layer prod/app
  members:
  - !host app-01
  - !host app-02
{% endhighlight %}
