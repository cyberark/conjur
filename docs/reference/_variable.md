{% include toc.md key='statement-reference' section='variable' %}

A variable provides encrypted, access-controlled storage and retrieval of arbitrary data values. Variable values are also versioned. The last 20 historical versions of the variable are available through the API; the latest version is returned by default.

Values are encrypted using aes-256-gcm. The encryption used in Conjur has been independently verified by a professional, paid cryptographic auditor.

#### Attributes

* **id**
* **kind** (string) Assigns a descriptive kind to the variable, such as 'password' or 'SSL private key'.
* **mime_type** (string) The expected MIME type of the values. This attribute is used to set the Content-Type header on HTTP responses.

#### Privileges

* **read** Permission to view the variable's metadata (e.g. annotations).
* **execute** Permission to fetch the default value or any historical value.
* **update** Permission to add a new value.

Note that `read`, `execute` and `update` are separate privileges. Having `execute` privilege does not confer `read`; nor does `update` confer `execute`.

#### Example

{% highlight yaml %}
- &variables
  - !variable
    id: db-password
    kind: password

  - !variable
    id: ssl/private_key
    kind: SSL private key
    mime_type: application/x-pem-file

- !layer app

- !permit
  role: !layer app
  privileges: [ read, execute ]
  resources: *variables
{% endhighlight %}

