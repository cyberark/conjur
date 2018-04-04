# AuthnCore

This gem provides a standard set of methods to implement the core security
requirements of a Conjur custom authenticator.

## Usage

Using this core functionality within `cyberark/conjur` is supported by default, as the `authn-core` gem is included in the project Gemfile.

This gem assumes your custom authenticator accepts POST requests to `/[service-id]/users/[user-id]/authenticate`

To use `authn-core`, include the following commands in your custom authenticator to validate the authenticate request before performing any checks specific to your authenticator.

The example code below assumes your authenticator has received a request where the `service-id` is `sample/id` and the `user-id` is `host/sample-host`. It also assumes your custom authenticator is called `authn-example`

```
require 'authn_core'
auth_sec = AuthenticatorSecurityRequirements.new(authn_type: "example")
auth_sec.validate("sample/id", "host/sample-host")
```
an exception will be raised if:
- `authn-example/sample/id` is not whitelisted in the `CONJUR_AUTHENTICATORS
` environment variable on the Conjur node
- there is no `conjur/authn-example/sample/id` webservice in Conjur policy
- there is no role with id `host/sample-host`
- the `host/sample-host` role is not authorized with `authenticate` privileges o
n the `conjur/authn-example/sample/id` webservice
