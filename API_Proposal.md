### Summary of API Additions
* /authn-{authenticator}
  * POST
    * Accepts `authenticator-id` as a form parameter
    * Creates a new policy branch named: `conjur/authn-<authenticator>/<authenticator-id>`
    * Enables the `authn-<authenticator>/<authenticator-id>` in Conjur
    * Return values:
      * 201 & the loaded YAML policy file on successful creation
      * 422 If the `authenticator-id` field is unspecified
      * 409 If the specified `authenticator-id` already exists
* /authn-{authenticator}/{auth-id}
  * POST
    * Accepts A JSON request body. Note: The JSON body is treated as describing a single host if there is no `hosts` JSON field specified.
    * Creates (or updates) the `conjur/authn-<authenticator>/<auth-id>` policy branch to add the new host
    * Grants the new host permissions to the `conjur/authn-<authenticator>/<auth-id>/users` layer.
    * Return Values
      * 201 & The loaded YAML policy file on successful creation
      * 422 If the JSON body is invalid in some way (missing field/unreadable)
      * 409 If the specified host already exists (NOTE: we may want to also check if the specified `host` id already exists in another authenticator because it may indicate something unintentional is being done)
  * DELETE
    * Accepts a JSON body which either specifies a single "id" to delete or a "hosts" field which is a list of hosts to delete.
    * Deletes the given hosts from the `conjur/authn-<authenticator>/<auth-id>` policy branch
    * Return Values
      * 201 & the YAML policy used to perform the deletion
      * 422 If the JSON body is invalid
      * 409 If the specified host doesn't exist

### Activating an Authenticator Service
Currently the process for setting up an authenticator in Conjur involves loading a policy which declares a webservice
and a `layer` or `group` which is authorized for that service.

e.g. for activating a Kubernetes authenticator with id `authn-id`:
```yaml
- !policy
  id: conjur/authn-k8s/my-auth
  body:
  - !webservice

  - !policy
    id: ca
    body:
    - !variable
      id: cert
    - !variable
      id: key

  - !layer users

  - !permit
    resource: !webservice
    privilege: [ read, authenticate ]
    role: !layer users
```
The policy loaded to activate the webservice for any authenticator will look very similar, so the exposed granularity of writing/loading
your own policy makes the task more difficult. To simplify this process a new HTTP method should be added to the
`/authn-<authenticator>` endpoints which allow loading this policy in the background with a REST API request.

Here is an example of what a request may look like in cURL:
```shell-session
$ curl -H <auth-info> -X POST -F "authenticator-id=my-auth" https://<conjur-url>/authn-k8s
```
This request would automatically load the above policy into Conjur AND return a 201 response containing the written policy.

### Adding a Host to use the Authenticator
Currently given a policy declaring the webservice and its users layer the process for adding a host which can authenticate is to
load policy which declares the host(s) and grant them access to the webservice layer. 

e.g.
```yaml
- !policy
  id: conjur/authn-k8s/my-auth/apps
  body:
  - &hosts
    - !host
      id: test-app
      annotations:
        authn-k8s/namespace: test-app

    - !host
      id: second-app
      annotations:
        authn-k8s/namespace: second-app

- !grant
  role: !layer conjur/authn-k8s/my-auth/users
  members:
    - *conjur/authn-k8s/my-auth/hosts

```
This policy will add two hosts and grant them permissions to the webservice layer so they can use the
authenticator. Much of this granularity could be hidden from the user by adding a REST endpoint to
automate the task. By default new hosts would be declared in the `conjur/authn-<auth type>/<auth-id>/apps`
policy branch, new users would be declared in the `conjur/authn-<authenticator>/<auth-id>/users` policy branch.

Here is an example request in cURL:
`request-data.json`
```json
{
  "hosts": [
    {
      "id": "test-app",
      "authn-k8s/namespace": "test-app"
    },
    {
      "id": "second-app",
      "authn-k8s/namespace": "second-app"
    }
  ]
}
```
or for a single host:
`request-data.json`
```json
{
  "id": "test-app"
}
```

```shell-session
$ curl -H <auth-info> -H "Content-Type: application/json" -d @request-data.json https://conjur/authn-k8s/my-auth
```
This would create multiple new hosts at once and grant them permission to the `users` layer in the authentication webservice.
A successful request will return a 201 response and the YAML policy loaded into Conjur.
The endpoint would also allow for host deletions using the HTML `DELETE` function.

### Default Authenticator Webservice Policy Templates

Each authenticator has slightly different requirements as far as variables are concerned. The Kubernetes authenticator needs
`cert` and `key` variables where the Azure authenticator needs a `provider-uri` variable. This can be accomplished with a single
ERB template and an if-else ladder. An example which will work for LDAP, K8s, and Azure is shown below:

`authenticator-service.yaml.erb`
```yaml
- !policy
  id: conjur/<%= authenticator %>/<%= auth_id %>
  body:
  - !webservice
  <% if authenticator == "authn-k8s" %>
  - !policy
    id: ca
    body:
    - !variable
      id: cert
    - !variable
      id: key
  <% elsif authenticator == "authn-azure" %>
  - !variable provider-uri
  <% end %>
  - !layer users

  - !permit
    resource: !webservice
    privilege: [ read, authenticate ]
    role: !layer users
```
