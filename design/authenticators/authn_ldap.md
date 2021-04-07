**Note**: This design document has been ported from the original document
[here](https://github.com/cyberark/conjur/issues/524).

# Feature Overview
LDAP authentication allows a user to authenticate with Conjur using credentials stored in a remote LDAP source rather than their Conjur credentials. LDAP authentication works exactly as regular authentication, returning a JSON hash if the user authenticates successfully.

# Workflow
To enable the authenticator, the `CONJUR_AUTHENTICATORS` environment variable must be set on any Conjur node that may be servicing the authentication request, and it must include the string `authn-ldap/<authenticator-name>` in its comma-separated list of allowed authenticators (for example, `CONJUR_AUTHENTICATORS=authn-iam/aws,authn-ldap/o365`).

The authenticator webservice must be declared in Conjur policy:
```yml
- !policy
  id: conjur/authn-ldap/<authenticator-name>
  body:
  - !webservice

  - !group clients

  - !permit
    role: !group clients
    privilege: [ read, authenticate ]
    resource: !webservice
```
and the `clients` group can be used to entitle a user(s) to use the authenticator:
```yml
- !grant
  role: !group conjur/authn-ldap/<authenticator-name>/clients
  member: !user <username>
```

Once the authenticator has been properly configured, a user will be able to configure their environment to use LDAP authorization through the the Conjur CLI client, UI, or when using Summon by setting the `CONJUR_AUTHN_URL` environment variable:
```
CONJUR_AUTHN_URL = https://conjur.company.com/authn-ldap/<authenticator-name>/<service-account>/<username>/authenticate
```

To successfully use the LDAP authenticator to authenticate to Conjur (if entitled to do so in Conjur policy), a user needs their Conjur User ID to match their LDAP username.

# Implementation Details
The authenticator itself is a class `AuthnLdap` in `lib/authenticators`. It has an `authenticate` method that returns true if the username and password match LDAP, and otherwise returns false.
```
  def authenticate(username, password)
```

The core routes will be updated to include
```
post ':authenticator/:service_id(/:account)/:login/authenticate' => 'authenticate#authenticate'
```

The core [`AuthenticateController`](https://github.com/cyberark/conjur/blob/master/app/controllers/authenticate_controller.rb) will be updated to define a `validate_security_requirements` method:
```
  def validate_security_requirements service_id, user_id
    security_requirements.validate(service_id, user_id)
  end

  def security_requirements
    AuthenticatorSecurity.new(
      authn_type: @authn_type,
      account: @account,
      whitelisted_authenticators: ENV['CONJUR_AUTHENTICATORS']
    )
  end
```
and its `authenticate` method must be updated to query the custom authenticator instead of the standard authenticator when there is another authenticator in the request path. In addition, it must be checked that the custom authenticator meets the security standards, so this might look something like:
```
  case params[:authenticator]
    when 'authn_ldap'
      validate_security_requirements service_id, username
      AuthnLdap.new.authenticate(username, password)
    else
      conjur_login(username, password)
    end
```
