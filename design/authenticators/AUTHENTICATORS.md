# Using, securing, and creating authenticators

Authenticators allow you to customize the user login and authentication methods
for Conjur. There are two endpoints used by Conjur to authenticate users and
services to the API.

* '/login' is used to authenticate users with a username and password. This
  endpoint allows users to initially authenticate with a memorable password
  and exchange it for an API key. The format of this key is configurable by
  the authenticator.

* '/authenticate' is used to authenticate either a user or service and returns
  a short-lived access token for API requests.

## Existing Authenticators

Links to the current Authenticator Feature specs:
* [Authn-LDAP](authn_ldap.md)
* [Authn-IAM](authn_iam.md)
* [Authn-OIDC](authn_oidc.md)
* [Authn-Azure](authn_azure/authn_azure_solution_design.md)
* [Authn-GCP](authn_gcp/authn_gcp_solution_design.md)

## Authenticator Status
This feature allows the person who configures an authenticator to get immediate feedback on 
its configuration. If there was a problem during the authenticator configuration process, 
the reason will be returned to the user so that they can make the necessary changes.

Click [here](authenticators-status/authn_status_general.md) for more details on this feature.

## Login

Successful login returns an API key that can be used for authentication. A
separate login step allows users to authenticate with a memorable password,
while using a random, rotatable access key for actual API authentication.

To login, send a `GET` request to:
```
/:authenticator-type/:optional-service-id/:conjur-account/login
```
[Basic Authentication](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication)
is used to send the username and password.

Let's break down the required pieces of this request:

- **authenticator-type:** The default Conjur authenticator type is `authn`, and
  all other authenticator types begin with the prefix `authn-`. For example,
  `authn-ldap` or `authn-my-awesome-authenticator`.

- **optional-service-id:** This is useful when you have two different
  "instances" of the same authenticator type.  For example, your company might
  have two LDAP directories, one for system administrators and one for
  developers.  These could both be enabled and accessed at the URLs
  `/authn-ldap/sysadmins/...` and `/authn-ldap/developers/...`.

- **conjur-account:** The Conjur account you'll be issued a token for.

- **username:** The username (from the point of view of the authenticator) of
  the person (or machine) requesting authentication.  In the case of default
  Conjur authentication, this would be your Conjur username.  In the case of
  LDAP authentication, this would be your LDAP username.

The plain text response body will contain the API key for the user.

## Authentication

Successful authentication returns a new **Conjur token**, which you can use to
make subsequent requests to protected Conjur services.

To authenticate and receive this token, `POST` to:
```
/:authenticator-type/:optional-service-id/:conjur-account/:username/authenticate
```
with the key (or other credential relevant to your authenticator) as plain
text in the request body.

The request parameters are the same as login with the addition of:

- **request body:** The plain text password or other credential relevant to
  your authenticator.  This could be an ordinary password, an API key, an
  OAuth token, etc -- depending on the type of authenticator.


## Security requirements

### Must allowlist before using

With the exception of the default Conjur authenticator named `authn`, all
authenticators must be explicitly allowlisted via the environment variable
`CONJUR_AUTHENTICATORS`.

1. If the environment variable `CONJUR_AUTHENTICATORS` is *not* set, the
   default Conjur authenticator will be automatically allowlisted and ready for
   use.  No other authenticators will be available in this case.
2. If the environment variable `CONJUR_AUTHENTICATORS` *is* set, then only the
   authenticators listed will be allowlisted.  This means that if
   `CONJUR_AUTHENTICATORS` is set and `authn` is not in the list, default
   Conjur authentication will not be available.

Here is an example `CONJUR_AUTHENTICATORS` which allowlists an LDAP
authenticator as well as the default Conjur authenticator:
```
CONJUR_AUTHENTICATORS=authn-ldap/sysadmins,authn
```

Note that this is a comma-separated list.

### Create webservice and authorize users

Except for the default Conjur authenticator, authenticators must be listed as
webservices in your Conjur policy, and users must be authorized to use them.
This requires two steps:

1. Add the authenticator as a webservice in your conjur policy:
```yaml
- !policy
  id: conjur/my-authenticator/optional-service-id
```
2. Add any users that need to access it to your policy, and grant them the
   `authenticate` privilege.


## Creating custom authenticators:

1. Create a new directory under `/app/domain/authentication`.  For example:
```
/app/domain/authentication/my_authenticator
```
2. That directory must contain a file named `authenticator.rb`, with the
   following structure:
```ruby
module Authentication
  module MyAuthenticator

    class Authenticator
      def initialize(env:)
        # initialization code based on ENV config
      end

      def login(input)
        # OPTIONAL
        # Implement `login` if your authenticator will
        # accept end-user credentials in exchange for a
        # token the user can used to authenticate with this
        # same authenticator.
        #
        # input has 5 attributes:
        #
        #     input.authenticator_name
        #     input.service_id
        #     input.account
        #     input.username
        #     input.credentials
        #
        # return either
        #   - a `string` containing the authentication key if successful
        #   - `nil` if the authentication is not successful
      end

      def valid?(input)
        # input has 5 attributes:
        #
        #     input.authenticator_name
        #     input.service_id
        #     input.account
        #     input.username
        #     input.credentials
        #
        # return true for valid credentials, false otherwise
      end
    end

  end
end
```

### Other Notes

1. Your authenticator directory can contain other supporting files used by your
   authenticator.
2. Conjur will instantiate your authenticator at boot up.  By default, when your
   authenticator is instantiated by conjur, it will be passed the `ENV` through
   the kwarg `env`.  If you don't need any configuration from the environment,
   you can opt out like so:
```ruby
module Authentication
  module MyAuthenticator

    class Authenticator
      def self.requires_env_arg?
        false
      end

      def initialize
        # you could also omit this altogether
      end

      def valid?(input)
        # same as before
      end
    end

  end
end
```

### Technical Notes

This section should only be relevant to Conjur developers.  These are notes on
the design of authenticator system itself:

- The architecture is objects nested like Russian dolls.  All dependencies are
  passed explicitly through the constructor.
- It also uses `Dry::Struct` quite a bit.  You can think of this like an
  `ostruct` with built-in type checking, which cleans up what would otherwise
  be verbose validation and initialization code.
