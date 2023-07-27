# OIDC Authenticator Configuration Improvements

## Issue Description
There have been multiple instances where users of the OIDC authenticator have experienced limitations resulting from our use of the third-party [OpenIDConnect gem](https://github.com/nov/openid_connect). The issues mainly stem from the gem limiting changes to the HTTP config used for outgoing connections. So far the following problems have been identified:
- Unable to configure CA certs from the authenticator config in Conjur
  - The workaround for custom CA certs is to add them to the Conjur container OpenSSL truststore (`/etc/ssl/certs`)
- The underlying HTTP client does not honor the `HTTPS_PROXY` environment variable
- Limited ability to debug OIDC-related HTTP errors

## Solution
An existing workaround for the CA cert issue mentioned previously involves a user manually updating the OpenSSL truststore in the container to include any custom CA certs. 

We can leverage this idea in Conjur to do the same thing on the fly. A simple wrapper method which creates a temporary truststore in the container and sets the OpenSSL environment variable `SSL_CERT_FILE` to point to this tempfile should be sufficient. Cleanup involves unsetting or resetting the environment variable to its original value, and ensuring that the tempfile has been cleaned up after code execution.

An example of what this wrapper method may look like:
```ruby
def with_temporary_cert_store(cert_string)
  Dir.mktmpdir do |temp_dir|
    temp_file = File.join(temp_dir, 'ca.pem')
    File.write(temp_file, cert_string)

    original_value = ENV['SSL_CERT_FILE']
    ENV['SSL_CERT_FILE'] = temp_file

    yield
  ensure
    original_value ? ENV['SSL_CERT_FILE'] = original_value : ENV.delete('SSL_CERT_FILE')
  end
end
```

And its usage:
```ruby
::Conjur::CertUtils.with_temporary_cert_store(@ca_cert) do
  @discovered_provider = @open_id_discovery_service.discover!(@provider_uri)
end
```

As for the `HTTPS_PROXY` issue, it appears to be fixed in a more recent version of OpenIDConnect gem which migrated from the `httpclient` library to `faraday` for handling outbound connections. Therefore we should simply be able to bump this gem version (assuming no new issues arise) in order to address this issue.

The last major concern was around better debug logging. This can also be enabled from the Conjur side, via a code snippet like below:
```
OpenIDConnect.logger = WebFinger.logger = SWD.logger = Rack::OAuth2.logger = Rails.logger
OpenIDConnect.debug!
# Include cert-related debug messages?
OpenSSL.debug = true
```
Running the above in an initializer and will enable debug logging on the OpenIDConnect gem and all its relevant dependencies and ensure that they get routed to the Rails logger. We could also include the debug logs for OpenSSL if we need to specifically focus on certificate-related debugging, which seems to be a common sticking point for authn-oidc users.

### Components
1. OpenIDConnect - primary gem for [generating an OIDC client](https://github.com/cyberark/conjur/tree/master/app/domain/authentication/authn_oidc/v2/client.rb#L106C20-L106C20) in authn-oidc which can retrieve authorization codes and tokens from the OIDC provider. It outsources discovery to a couple other small gems which we need to consider as well:
1. SWD (Simple Web Discovery) - handles OIDC configuration discovery against the provider URI configuration endpoint: `/.well-known/openid-configuration` 
1. WebFinger - used for dynamic discovery when the credential issuer is unknown to the client. **Not used in Conjur.**

### Considerations around OIDC Discovery
The SWD gem discussed previously is used by OpenIDConnect across many authenticators in Conjur (authn-oidc, authn-jwt, authn-azure, authn-gcp). It performs a couple common tasks in Conjur by invoking the OIDC discovery endpoint:
  - validate authenticator status and provider connectivity
  - fetch provider keys for decoding tokens

This should not interfere with the proposed solution, but it is important to note since the modified code will be used across different authenticators to invoke the provider discovery endpoint `/.well-known/openid-configuration`. It will be necessary that the other authenticators are unaffected by this change.

### Testing
The testing will depend on the final implementation, but at the very least the wrapper method will need to be well-covered by unit tests.

#### Unit tests (temporary truststore)
1. OpenSSL environment variable is set while yielding
1. OpenSSL environment variable is unset after yielding (if originally unset)
1. OpenSSL environment variable is reset after yielding (if had previous value)
1. Temp file exists while yielding
1. Temp file contains expected content while yielding
1. Temp file is removed after yielding

#### Unit tests (authenticator data object)
1. Default `ca-cert` value is nil
1. Set value matches expected

#### Cucumber tests
One or more of our Keycloak OIDC scenarios should be updated to use a `ca-cert` value provided via Conjur variable. It may turn out to be easier to update all keycloak examples to use the cert variable, and the case where the variable is not set can be covered by the Okta examples.

### Open Questions
- Do we need validation that `ca-cert` is a valid cert before attempting to use it?
- Should debug logging of OIDC be enabled by default when Conjur is running in debug?
- Should OpenSSL debug logs be included?

## Tasks
### 1. Update the OpenIDConnect gem (1 pt)
Upgrade our OpenIDConnect gem to >= 2.0.0 (when it switched from `httpclient` to `faraday`) and ensure nothing breaks.

### 2. Create a temporary truststore wrapper method (2 pts)
Create a method which accepts a string (`ca_cert`) and writes a temporary truststore in the container (as a pem file), updates the `SSL_CERT_FILE` environment variable, and yields to another method. Add tests to ensure expected state during code execution and cleanup has occured afterwards.

I would suggest adding it to the [CertUtils module](https://github.com/cyberark/conjur/blob/master/app/domain/conjur/cert_utils.rb).

### 3. Add support for `ca-cert` variable in authn-oidc config (2 pts)
Allow an optional `ca-cert` variable to be set in Conjur which will eventually be passed to our temporary truststore method. It should be tied to the authenticator instance data object so that multiple authn-oidc instances are supported, each with unique (or non-existent) `ca-cert` values. Update tests to ensure that the `ca-cert` variable exists as expected on the relevant authenticator instance.

### 4. Wrap all calls to OpenIDConnect (2 pts)
Implement the wrapper function around any calls to OpenIDConnect which connect to the provider and are invoked by authn-oidc. Includes at least the following: 
1. [Validate connectivity for status endpoint (shared with other authenticators)](https://github.com/cyberark/conjur/tree/master/app/domain/authentication/o_auth/discover_identity_provider.rb#L31) 
1. [Fetch provider information](https://github.com/cyberark/conjur/tree/master/app/domain/authentication/authn_oidc/v2/client.rb#L106) 
1. [Fetch access token](https://github.com/cyberark/conjur/tree/master/app/domain/authentication/authn_oidc/v2/client.rb#L44)

Ensure it works regardless of whether `ca-cert` is set. Pay special attention [during this discovery step](https://github.com/cyberark/conjur/tree/master/app/domain/authentication/o_auth/discover_identity_provider.rb#L31) which is used by other authenticators, all of which should use the default SSL config as before (even if they technically support their own `ca-cert` variable).

### 5. Add debug logging for authn-oidc (1 pt)
Enable debug logging on `openid_connect` and relevant gems based on `CONJUR_LOG_LEVEL`. We may also want to include OpenSSL logs.
```
OpenIDConnect.logger = WebFinger.logger = SWD.logger = Rack::OAuth2.logger = Rails.logger
OpenIDConnect.debug!
OpenSSL.debug = true
```

### 6. Update dev environment and cucumber scenarios (2 pts)
Update the dev environment and e2e tests which run against keycloak to set the `ca-cert` via Conjur policy rather than copying the cert file into the container. Currently this is handled by the script `ci/oauth/keycloak/fetch_certificate`.

### 7. Update docs with the new configuration options (1 pt)
Identify which docs need to be updated and where. Provide feedback to tech writers.

### 8. (TW) Update OIDC authenticator docs (1 pt)
Update OIDC authenticator docs based on new configuration options.
