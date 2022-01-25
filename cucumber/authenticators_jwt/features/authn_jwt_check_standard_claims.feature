@authenticators_jwt
Feature: JWT Authenticator - Check registered claim

  Verify the authenticator works correctly with the registered claims:
   - iat
   - exp
   - nbf
   - iss
   - aud

  Background:
    Given I initialize remote JWKS endpoint with file "authn-jwt-check-standard-claims" and alg "RS256"
    And I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: token-app-property

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice

    - !policy
      id: conjur/authn-jwt/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for JWT tokens, based on Keycloak as OIDC provider.

      - !variable
        id: provider-uri

      - !variable
        id: token-app-property

      - !variable
        id: issuer

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice

    - !host
      id: alice
      annotations:
        authn-jwt/keycloak/email: alice@conjur.net

    - !grant
      role: !group conjur/authn-jwt/keycloak/hosts
      member: !host alice

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am the super-user
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I have a "variable" resource called "test-variable"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I permit host "alice" to "execute" it

  @acceptance
  Scenario: ONYX-8727: Issuer configured with incorrect value, iss claim not exists in token, 200 ok
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: jwks-uri

      - !variable
        id: issuer
    """
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-check-standard-claims/RS256" in service "raw"
    And I successfully set authn-jwt "issuer" variable to value "incorrect-value"
    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with raw service ID
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @negative @acceptance
  Scenario: ONYX-8714: JWT token with past exp claim value, 401 Error
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: jwks-uri
    """
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-check-standard-claims/RS256" in service "raw"
    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject",
      "exp": 0
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with raw service ID
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00016E Token expired
    """

  @negative @acceptance
  Scenario: ONYX-8711: Valid JWT token with no exp claim, 401 Error
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: jwks-uri
    """
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-check-standard-claims/RS256" in service "raw"
    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue non exp token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with raw service ID
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00091E Failed to validate token: mandatory claim 'exp' is missing.
    """

  @negative @acceptance
  Scenario: ONYX-8715: JWT token with future iat claim, 401 Error
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: jwks-uri
    """
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-check-standard-claims/RS256" in service "raw"
    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject",
      "iat": 7624377528
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with raw service ID
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::InvalidIatError: Invalid iat>')>
    """

  @negative @acceptance
  Scenario: ONYX-8716: JWT token with future nbf claim, 401 Error
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: jwks-uri
    """
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-check-standard-claims/RS256" in service "raw"
    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject",
      "nbf": 7624377528
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with raw service ID
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::ImmatureSignature: Signature nbf has not been reached>')>
    """

  @negative @acceptance
  Scenario: ONYX-8718: issuer configured but not set, iss claim exists in token, 401 Error
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: jwks-uri

      - !variable
        id: issuer
    """
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-check-standard-claims/RS256" in service "raw"
    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject",
      "iss": "issuer"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/issuer
    """

  @acceptance
  Scenario: ONYX-8719: issuer configured but not set, iss claim not exists in token, 200 ok
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: jwks-uri

      - !variable
        id: issuer
    """
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-check-standard-claims/RS256" in service "raw"
    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/issuer
    """

  @acceptance
  Scenario: ONYX-8728: jwks-uri configured with correct value, issuer configured with correct value, iss claim with correct value, 200 OK
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: jwks-uri

      - !variable
        id: issuer
    """
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-check-standard-claims/RS256" in service "raw"
    And I successfully set authn-jwt "issuer" variable to value "http://jwks"
    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject",
      "iss": "http://jwks"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with raw service ID
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @negative @acceptance
  Scenario: ONYX-8728: jwks-uri configured with correct value, issuer configured with wrong value, iss claim with correct value, 401 Error
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: jwks-uri

      - !variable
        id: issuer
    """
    And I successfully set authn-jwt "issuer" variable to value "incorrect.com"
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-check-standard-claims/RS256" in service "raw"
    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject",
      "iss": "http://jwks"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::InvalidIssuerError: Invalid issuer. Expected incorrect.com, received http://jwks>')>
    """

  @negative @acceptance
  Scenario: ONYX-8728: jwks-uri configured with wrong value, issuer configured with wrong value, iss claim with correct value, 401 Error
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: jwks-uri

      - !variable
        id: issuer
    """
    And I successfully set authn-jwt "jwks-uri" variable to value "incorrect.com"
    And I successfully set authn-jwt "issuer" variable to value "incorrect.com"
    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject",
      "iss": "http://jwks_py:8090/authn-jwt-check-standard-claims/RS256"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00087E Failed to fetch JWKS from 'incorrect.com'
    """

  @negative @acceptance
  Scenario: ONYX-8728: provider-uri configured with wrong value, issuer configured with wrong value, iss claim with correct value, 502 Error
    Given I successfully set authn-jwt "provider-uri" variable in keycloack service to "incorrect.com"
    And I successfully set authn-jwt "token-app-property" variable with OIDC value from env var "ID_TOKEN_USER_PROPERTY"
    And I successfully set authn-jwt "issuer" variable with OIDC value from env var "PROVIDER_ISSUER"
    And I fetch an ID Token for username "alice" and password "alice"
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the ID token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00011E Failed to discover Identity Provider (Provider URI: 'incorrect.com'). Reason: '#<AttrRequired::AttrMissing: 'host' required.>'
    """

  @negative @acceptance
  Scenario: ONYX-15323: public-keys with invalid issuer variable
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/public-keys
    - !variable conjur/authn-jwt/raw/issuer
    """
    And I successfully set authn-jwt public-keys variable to value from remote JWKS endpoint "authn-jwt-check-standard-claims" and alg "RS256"
    And I successfully set authn-jwt "issuer" variable to value "invalid-issuer"
    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject",
      "iss": "valid-issuer"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::InvalidIssuerError: Invalid issuer. Expected invalid-issuer, received valid-issuer>')>
    """

  @sanity
  @acceptance
  Scenario Outline: Audience tests
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/jwks-uri
    - !variable conjur/authn-jwt/raw/audience

    - !host
      id: aud-test-app
      annotations:
        authn-jwt/raw/project_id: valid-project-id

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host aud-test-app
    """
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-check-standard-claims/RS256" in service "raw"
    And I successfully set authn-jwt "audience" variable to value "<audience>"
    And I am using file "authn-jwt-check-standard-claims" and alg "RS256" for remotely issue token:
    """
    {
      "project_id":"valid-project-id",
      "host":"aud-test-app",
      <aud>
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is <http_code>
    And The following appears in the log after my savepoint:
    """
    <log>
    """
    Examples:
      | Test       | audience        | aud                                         | http_code | log                                                                                                                                       |
      | ONYX-11154 | valid-audience  | "other":"claim"                             | 401       | CONJ00091E Failed to validate token: mandatory claim 'aud' is missing.                                                                    |
      | ONYX-11156 | valid-audience  | "aud":"invalid"                             | 401       | CONJ00018D Failed to decode the token with the error '#<JWT::InvalidAudError: Invalid audience. Expected valid-audience, received invalid |
      | ONYX-11158 | valid-audience  | "aud": ["value1","valid-audience","value2"] | 200       | cucumber:host:aud-test-app successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw       |
