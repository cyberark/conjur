{% include toc.md key='statement-reference' section='webservice' %}

Represents a web service endpoint, typically an HTTP(S) service.

Permission grants are straightforward: an input HTTP request path is mapped to a webservice resource id. The HTTP method is mapped to an RBAC privilege. A permission check is performed, according to the following transaction:

* **role** client role on the HTTP request. The client can be obtained from an Authorization header (e.g. signed access token), or from the subject name of an SSL client certificate.
* **privilege** typically `read` for read-only HTTP methods, and `update` for POST, PUT and PATCH.
* **resource** web service resource id

#### Example

{% highlight yaml %}
- !group analysts

- !webservice
  id: analytics

- !permit
  role: !group analysts
  privilege: read
  resource: !webservice analytics
{% endhighlight %}

