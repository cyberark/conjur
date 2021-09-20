# Managing Connection Info
* Add new type of variable which bundles multiple values into one. Upon retrieval returns JSON which
  bundles all of the variable values into one. This would look similar to the batch secrets retrieval
  endpoint but be more user friendly for a single connection.
  e.g. in policy:
  ```yaml
  - !connection
    id: my-database-info
    variables:
    - !variable database-url
    - !variable database-username
    - !variable database-password
  ```
  ## Setting the values:
  ```shell
  $ curl -H <auth-info> \
    -d '{"database-url": "https://url","database-username":"admin","database-password":"password"}' \
    https://<conjur-url>/secrets/<account>/connection/my-database-info
  ```
  You could also just set some of the values without updating others:
  ```shell
  $ curl -H <auth-info> \
    -d '{"database-username":"bob","database-password":"bob-password"}' \
    https://<conjur-url>/secrets/<account>/connection/my-database-info
  ```
  ## Retrieving the values
  ```shell
  $ curl -H <auth-info> https://<conjur-url>/secrets/<account>/connection/my-database-info
  ```
  returns:
  ```json
  {
    "database-url": "https://url",
    "database-username": "admin",
    "database-password": "password"
  }
  ```
* Policy for creating the actual k8s authn webservice in conjur could be automated. Currently it looks
  similar to this:
  ```yaml
  - !policy
    id: conjur/authn-k8s/authenticator-id
    body:
    - !webservice

    - !policy
      id: ca
      body:
      - !variable
        id: cert
      - !variable
        id: key

    # define layer of whitelisted authn ids permitted to call authn service
    - !layer users

    - !permit
      resource: !webservice
      privilege: [ read, authenticate ]
      role: !layer users

  - !grant
    role: !layer conjur/authn-k8s/authenticator-id/users
    members:
      - !layer conjur/authn-k8s/authenticator-id/apps
  ```
  The webservice, certificate variables, and users layer could all automatically be built with an
  API call that specified the authenticator ID and layer name.
  e.g.
  ```shell
  $ curl -H <auth-info> -X POST -F "authenticator-id=my-auth" -F "authenticator-layer=users" https://<conjur-url>/authn-k8s
  ```
  This could also be generalized to the other authenticators, allowing the easy creation of the new authenticator webservice
  without having to deal with creating and loading new policy.
