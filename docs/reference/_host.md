{% include toc.md key='statement-reference' section='host' %}

A server, VM, script, job, or container, or any other type of coded or automated actor.

Hosts defined in a policy are generally long-lasting hosts, and assigned to a
layer through a `!grant` entitlement. Assignment to layers is the primary way
for hosts to get privileges, such as access to variables.

Hosts can authenticate using `host/<id>` as the login and their API key as the credential. When a new host is created, it's assigned a randomly generated API key. The API key can be reset (rotated) by an administrative user if it is lost or compromised. 

#### Attributes

* **id**

#### Example

{% highlight yaml %}
- !layer webservers

- !host
  id: www-01
  annotations:
    description: Hypertext web server
        
- !grant
  role: !layer webservers
  member: !host www-01
{% endhighlight %}

