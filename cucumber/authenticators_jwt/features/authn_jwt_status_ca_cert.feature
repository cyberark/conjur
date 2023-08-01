@authenticators_jwt
Feature: JWT Authenticator - ca-cert variable tests

  Validate the authenticator behavior when ca-cert variable is configured.
  All tests are using status API for validation.

  Background:
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice
      - !variable jwks-uri
      - !webservice status
    """

  @negative @acceptance
  Scenario: ONYX-15311: Self-signed jwks-uri no ca-cert variable
    Given I initialize JWKS endpoint with file "ca-cert-ONYX-15311.json"
    And I am the super-user
    And I successfully set authn-jwt "jwks-uri" variable to value "https://jwks/ca-cert-ONYX-15311.json"
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00087E Failed to fetch JWKS from 'https://jwks/ca-cert-ONYX-15311.json'. Reason: '#<OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 state=error: certificate verify failed (self signed certificate)>'>"

  @sanity
  @acceptance
  Scenario: ONYX-15312: Self-signed jwks-uri with valid ca-cert variable value
    Given I initialize JWKS endpoint with file "ca-cert-ONYX-15312.json"
    And I am the super-user
    And I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/ca-cert
    """
    And I successfully set authn-jwt "jwks-uri" variable to value "https://jwks/ca-cert-ONYX-15312.json"
    And I fetch root certificate from https://jwks endpoint as "self"
    And I successfully set authn-jwt "ca-cert" variable value to the "self" certificate
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds

  @acceptance
  Scenario Outline: ONYX-15313/6: Self-signed jwks-uri with ca-cert contains bundle includes the valid certificate
    Given I initialize JWKS endpoint with file "ca-cert-ONYX-15313.json"
    And I initialize JWKS endpoint with file "ca-cert-ONYX-15316.json"
    And I am the super-user
    And I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/ca-cert
    """
    And I successfully set authn-jwt "jwks-uri" variable to value "<jwks-uri>"
    And I fetch root certificate from https://jwks endpoint as "self"
    And I fetch root certificate from https://chained.mycompany.local endpoint as "chained"
    And I bundle the next certificates as "bundle":
    """
    chained
    self
    """
    And I successfully set authn-jwt "ca-cert" variable value to the "bundle" certificate
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds
    Examples:
      | jwks-uri                                                |
      | https://jwks/ca-cert-ONYX-15313.json                    |
      | https://chained.mycompany.local/ca-cert-ONYX-15316.json |

  @negative @acceptance
  Scenario: ONYX-15314: Chained jwks-uri no ca-cert variable
    Given I initialize JWKS endpoint with file "ca-cert-ONYX-15314.json"
    And I am the super-user
    And I successfully set authn-jwt "jwks-uri" variable to value "https://chained.mycompany.local/ca-cert-ONYX-15314.json"
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00087E Failed to fetch JWKS from 'https://chained.mycompany.local/ca-cert-ONYX-15314.json'. Reason: '#<OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 state=error: certificate verify failed (self signed certificate in certificate chain)>'>"

  @sanity
  @acceptance
  Scenario: ONYX-15315: Self-signed jwks-uri with valid ca-cert variable value
    Given I initialize JWKS endpoint with file "ca-cert-ONYX-15315.json"
    And I am the super-user
    And I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/ca-cert
    """
    And I successfully set authn-jwt "jwks-uri" variable to value "https://chained.mycompany.local/ca-cert-ONYX-15315.json"
    And I fetch root certificate from https://chained.mycompany.local endpoint as "chained"
    And I successfully set authn-jwt "ca-cert" variable value to the "chained" certificate
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds

  @acceptance
  Scenario: ONYX-15317: Google's jwks-uri no ca-cert variable
    Given I am the super-user
    And I successfully set authn-jwt "jwks-uri" variable to value "https://www.googleapis.com/oauth2/v3/certs"
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds

  @sanity
  @negative @acceptance
  Scenario: ONYX-15318: Microsoft's jwks-uri with invalid ca-cert variable value
    Given I am the super-user
    And I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/ca-cert
    """
    And I successfully set authn-jwt "jwks-uri" variable to value "https://login.microsoftonline.com/common/discovery/v2.0/keys"
    And I fetch root certificate from https://chained.mycompany.local endpoint as "chained"
    And I successfully set authn-jwt "ca-cert" variable value to the "chained" certificate
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00087E Failed to fetch JWKS from 'https://login.microsoftonline.com/common/discovery/v2.0/keys'. Reason: '#<OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 state=error: certificate verify failed (unable to get local issuer certificate)>'>"
