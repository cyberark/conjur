{% include toc.md key='statement-reference' section='user' %}

A human user. For servers, VMs, scripts, PaaS applications, and other code actors, create hosts instead of users.

Users can authenticate using their `id` as the login and their API key as the credential. When a new user is created, it's assigned a randomly generated API key. The API key can be reset (rotated) by an administrative user if it is lost or compromised. 

Users can also be assigned a password. A user can use her password to `login` and obtain her API key, which can be used to authenticate as described above. Further details on login and authentication are provided in the API documentation.

#### Attributes

* **id** Should not contain special characters such as `:/`. It may contain the `@` symbol.
* **public_keys** Stores public keys for the user, which can be retrieved through the public keys API.

#### Example

{% highlight yaml %}
- !user
  id: kevin
  public_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAAD...+10trhK5Pt kgilpin@laptop

- !group
  id: ops

- !grant
  role: !group ops
  member: !user kevin
{% endhighlight %}

