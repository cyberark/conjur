# OIDC Authenticator Configuration Improvements

## Issue Description
There have been multiple instances where users of the OIDC authenticator have experienced limitations resulting
from our use of the third-party [OpenIDConnect gem](https://github.com/nov/openid_connect). The issues mainly stem
from the gem limiting changes to the HTTP config used for outgoing connections. So far the following problems have
been identified:
- Unable to configure CA certs from the authenticator config in Conjur
  - The workaround for custom CA certs is to add them to the Conjur container OpenSSL truststore (`/etc/ssl/certs`)
- The underlying HTTP client does not honor the `HTTPS_PROXY` environment variable
- Limited ability to debug OIDC-related HTTP or TLS errors

### Components
Within Conjur, the following components handle the logic for connecting to the configured OIDC provider:
1. OpenIDConnect - primary gem for [generating an OIDC client](https://github.com/cyberark/conjur/tree/master/app/domain/authentication/authn_oidc/v2/client.rb#L106C20-L106C20) in
authn-oidc which can retrieve authorization codes and tokens from the OIDC provider. It outsources discovery
to a couple other small gems which we need to consider as well:
1. SWD (Simple Web Discovery) - handles OIDC configuration discovery against the provider URI configuration
endpoint: `/.well-known/openid-configuration`

### Considerations around OIDC Discovery
The OpenIDConnect `discover` method is used across multiple authenticators in Conjur (authn-oidc,
authn-jwt, authn-azure, authn-gcp). It plays a role in a couple generic tasks in Conjur by invoking the OIDC discovery
endpoint:
  - validate authenticator status and provider connectivity
  - fetch provider keys for decoding tokens

This should not interfere with the proposed solution, but it is important to note since this [call to the `discover` method](https://github.com/cyberark/conjur/blob/48e95904a5ee8cda1503db9f5744ff6eefcecbdb/app/domain/authentication/o_auth/discover_identity_provider.rb#L31C40-L31C40)
may be used across different authenticators to invoke the provider discovery endpoint `/.well-known/openid-configuration`.
It will be necessary that other authenticators are unaffected by this change while the OIDC authenticator's status
endpoint can successfully use the configured CA cert in its call.

## Solution
It will be more consistent with other authenticator configs if authn-oidc were to support a `ca-cert` variable
in the authenticator policy. This value will inform the HTTP client which CA cert(s) to use to verify
the connection with an OIDC provider and/or any proxies that sit in the middle. An authenticator policy featuring
this variable may look like:
```
- !policy
  id: conjur/authn-oidc/<service-id>
  body:
  - !webservice
  - !variable token-ttl

  - !variable provider-uri
  - !variable client-id
  - !variable client-secret

  # CA Cert [Optional] - Use this to define a custom CA cert or cert chain to verify the connection with the OIDC provider
  - !variable ca-cert

  # Token TTL [Optional] - Use this to override default
  - !variable token-ttl

  # URI of Conjur instance
  - !variable redirect-uri

  # Defines the JWT claim to use as the Conjur identifier
  - !variable claim-mapping

  # Name [Optional] - Defines Name to display in Conjur-UI
  - !variable name

  # Provider-Scope [Optional] - Defines claim scope ie: openid email profile
  - !variable provider-scope

  # Status Webservice for authenticator
  - !webservice
    id: status
    annotations:
      description: Status service to check that the authenticator is configured correctly
 
  - !group
    id: operators
    annotations:
      description: Group of users who can check the status of the authenticator
 
  - !permit
     role: !group operators
     privilege: [ read ]
     resource: !webservice status

  - !group
    id: users
    annotations:
      description: Group of users who can authenticate using the authn-oidc/<service-id> authenticator

  - !permit
    role: !group users
    privilege: [ read, authenticate ]
    resource: !webservice

#---
# Need to grant user members to role
- !grant
  members:
  - !user testuser1@mycompany.com
  role: !group conjur/authn-oidc/<service id>/users
```

Unfortunately the OpenIDConnect gem does not provide a way to reconfigure its HTTP client with custom
SSL options. To workaround this we can leverage a similar flow as the existing workaround, where we will
temporarily update the OpenSSL trusted certificate store with a copy of the certificate(s) represented
by the value of the `ca-cert` variable which will then be used to verify the connection with the OIDC
provider.

## Implementation
A wrapper method which creates a temporary symlink in the OpenSSL
truststore to a tempfile containing the certificate content should be sufficient. Cleanup involves
removing the symlink, and ensuring that the tempfile has been cleaned up after code execution. Since we
are (temporarily) adding the cert to the existing truststore, it should not interfere with concurrent
HTTP connections which may rely on the default OpenSSL certs still being available.

An example of what this wrapper method may look like in the case of provider config discovery:
```ruby
def discover_with_temporary_cert_store(open_id_discovery_service, provider_uri, cert_string)
  Dir.mktmpdir do |temp_dir|
    # Write the certificate to a temporary file
    temp_file = File.join(temp_dir, 'ca.pem')
    File.write(temp_file, cert_string)

    # Compute the X.509 hash of the certificate subject and create a symlink to the temp file
    cert = OpenSSL::X509::Certificate.new(cert_string)
    symlink_name = File.join(OpenSSL::X509::DEFAULT_CERT_DIR, "#{cert.subject.hash.to_s(16)}.0")
    File.symlink(temp_file, symlink_name)

    open_id_discovery_service.discover!(provider_uri)
  ensure
    File.unlink(symlink_name) if File.symlink?(symlink_name)
  end
end
```

Usage:
```ruby
discover_with_temporary_cert(@open_id_discovery_service, @provider_uri, @ca_cert)
```

A similar method will be needed to wrap the [`access_token!` method](https://github.com/cyberark/conjur/blob/48e95904a5ee8cda1503db9f5744ff6eefcecbdb/app/domain/authentication/authn_oidc/v2/client.rb#L44)
used by the OIDC authenticator. We choose to make two separate wrappers rather than a generic one which
yields to a code block in order to prevent unintentional or ambiguous use of the method due to
its security implications.

We can easily support cert chains and perform basic validation using the existing [parse_certs](https://github.com/cyberark/conjur/blob/48e95904a5ee8cda1503db9f5744ff6eefcecbdb/app/domain/conjur/cert_utils.rb#L11C10-L11C10) method.

As for the `HTTPS_PROXY` issue, it appears to be fixed in a more recent version of OpenIDConnect gem which
migrated from the `httpclient` library to `faraday` for handling outbound connections. Therefore we should
simply be able to bump this gem version (assuming no new issues arise) in order to address this issue.

The last major concern was around better debug logging. This can also be enabled from the Conjur side,
via a code snippet like below:
```
OpenIDConnect.logger = WebFinger.logger = SWD.logger = Rack::OAuth2.logger = Rails.logger
OpenIDConnect.debug!
OpenSSL.debug = true
```
Running the above in an initializer and will enable debug logging on the OpenIDConnect gem and all its
relevant dependencies and ensure that they get routed to the Rails logger. We could also include the debug
logs for OpenSSL if we need to specifically focus on certificate-related debugging, which seems to be a
common sticking point for authn-oidc users.

### Security
The solution proposes adding a CA certificate (or chain) to the OpenSSL truststore of the Conjur container for
the duration of certain HTTP requests. This involves writing certificate contents to the container volume, creating
a symlink in the OpenSSL truststore, and yielding for the duration of the specific logic. Once this logic is complete,
the CA certificate and symlink will be removed.

#### Security Risks and Mitigations
**Certificate Management**: Temporary changes to truststores can lead to mismanagement of certificates, resulting in
leftover or unused certificates remaining in the truststore. Also we need to be sure that there are no circumstances
in which the certificate management process is interrupted.

**Mitigation**: Implement a thorough certificate management test suite that validates the addition, usage, and removal
of certificates.

**Log Verbosity and Information Disclosure**: Debugging TLS issues with an OIDC provider is overly difficult with the
current debug logging. We would like to expose additional logging from the OpenIDConnect gem (which makes requests to
the provider) and OpenSSL (which performs TLS verification based on the configured truststore). This requires that we
do not disclose any sensitive information with the additional debug logs.

**Mitigation**: Verify that logs for each of the components do not disclose sensitive data, including certificate
metadata or any OIDC related secrets in the HTTP request logs.

### Logs
| **Scenario** | **Level** | **Message** |
| - | - | - |
| One or more certs represented in the `ca-cert` variable can not be parsed | Error | Failed to parse certificate:\n{0-cert}\nError message: {1-error-message} |
| TLS verification fails when contacting the OIDC provider | Error | TLS verification failed for the OIDC provider: {0-provider-uri}. The ca-cert variable may need to be configured. |
| A CA cert is being temporarily added to the OpenSSL certificate store per the authenticator config | Debug | Updating OpenSSL certificate store for OIDC authenticator: {0-service-id} |

There will be more transparent debug logging not covered here as a result of enabling debug mode for the OpenIDConnect gem
and its dependencies, as well as OpenSSL.

### Testing
The testing strategy will vary depending on the final implementation, but at the very least the wrapper methods
will need to be well-covered by unit tests. Custom error/debug logging should be tested for as well.

#### Unit tests (temporary truststore modifications)
1. OpenSSL truststore contains the CA cert symlink while yielding
1. OpenSSL truststore symlink is removed after yielding
1. Hash collision in truststore does not produce an error but instead increments the file extension of the symlink
1. Cert chains work in addition to individual CA certs
1. Malformed certificates produce the expected error message
1. When a certificate parse error occurs, the authenticator still attempts to reach the provider.
1. Network errors produce the expected error message
1. Temp file/dir/symlink exists while contacting provider
1. Temp file/dir/symlink contains expected certificate content while contacting provider
1. Temp file/dir/symlink is removed after contacting provider
1. Empty or missing CA cert variable does not modify current behavior

#### Unit tests (authenticator data object)
1. Default `ca-cert` value is nil
1. Set value matches expected value

#### Cucumber tests
One or more of our Keycloak OIDC scenarios should be updated to use a `ca-cert` value provided via Conjur 
variable. It may turn out to be easier to update all keycloak examples to use the cert variable, and the case 
where the variable is not set can be covered by the Okta examples. If possible we need to test against certificate
chains as well as individual certs.

### Open Questions
- Do we need validation that `ca-cert` is a valid cert before attempting to use it?
Answer: Yes - this will be done while parsing the cert (or cert chain) into an OpenSSL::X509::Certificate object.
- Should debug logging of OIDC be enabled by default when Conjur is running in debug?
Answer: Yes, it should use the same debug toggle as the rest of Conjur.
- Should OpenSSL debug logs be included?
Answer: Yes, since some cert issues may occur outside the scope of the HTTP request, such as when a cert file has incorrect permissions.

## Tasks
### 1. Update the OpenIDConnect gem (1 pt)
Upgrade our OpenIDConnect gem to >= 2.0.0 (when it switched from `httpclient` to `faraday`) and fix any resulting
issues or test failures.

### 2. Create a temporary truststore wrapper method for OIDC discovery (3 pts)
Create a method which temporarily updates the default OpenSSL truststore, and invokes the
`discover` method. Add tests to ensure expected state during code execution and cleanup has occured 
afterwards.

### 3. Create a temporary truststore wrapper method for access token retrieval (2 pts)
Create a method which temporarily updates the default OpenSSL truststore, and invokes the
`access_token` method. Add tests to ensure expected state during code execution and cleanup has occured 
afterwards.

### 4. Add support for `ca-cert` variable in authn-oidc config (2 pts)
Allow an optional `ca-cert` variable to be set in Conjur which will eventually be passed to our temporary 
truststore methods. It should be tied to the authenticator instance data object so that multiple authn-oidc 
instances are supported, each with unique (or non-existent) `ca-cert` values. Update tests to ensure that the 
`ca-cert` variable exists as expected on the relevant authenticator data object.

### 5. Replace all calls to OpenIDConnect (2 pts)
Implement the wrapper methods for any calls to OpenIDConnect which connect to the provider and are invoked 
by authn-oidc. Includes at least the following: 
1. [Validate connectivity for status endpoint (shared with other authenticators)](https://github.com/cyberark/conjur/tree/master/app/domain/authentication/o_auth/discover_identity_provider.rb#L31) 
1. [Fetch provider information](https://github.com/cyberark/conjur/tree/master/app/domain/authentication/authn_oidc/v2/client.rb#L106) 
1. [Fetch access token](https://github.com/cyberark/conjur/tree/master/app/domain/authentication/authn_oidc/v2/client.rb#L44)

Ensure it works regardless of whether `ca-cert` is set. Pay special attention [during this discovery step](https://github.com/cyberark/conjur/tree/master/app/domain/authentication/o_auth/discover_identity_provider.rb#L31) 
which is used by other authenticators.

### 5. Add debug logging for authn-oidc (1 pt)
Enable debug logging on `openid_connect` and relevant gems based on `CONJUR_LOG_LEVEL`. We may also want to 
include OpenSSL logs.
```
OpenIDConnect.logger = WebFinger.logger = SWD.logger = Rack::OAuth2.logger = Rails.logger
OpenIDConnect.debug!
OpenSSL.debug = true
```

### 6. Update dev environment and cucumber scenarios (2 pts)
Update the dev environment and e2e tests which run against keycloak to set the `ca-cert` via Conjur policy rather 
than copying the cert file into the container. Currently this is handled by the script 
`ci/oauth/keycloak/fetch_certificate`.

### 7. Update docs with the new configuration options (1 pt)
Identify which docs need to be updated and where. Provide feedback to tech writers.

### 8. (TW) Update OIDC authenticator docs (1 pt)
Update OIDC authenticator docs based on new configuration options.
