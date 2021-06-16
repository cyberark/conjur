Feature: JWT Authenticator - Fetch identity from decoded token
  Background:
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice
        annotations:
          description: Authentication service for JWT tokens, based on raw JWKs.

      - !variable
        id: jwks-uri

      - !variable
        id: token-app-property

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/users
      member: !host myapp
    """
    And I am the super-user
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint

  Scenario: A valid JWT token with identity in the token
    Given I have a "variable" resource called "test-variable"
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario: Token identity configuration no matching any claim, error
    Given I issue a JWT token:
    """
    {
      "project-id": "myproject"
    }
    """
    And I successfully set authn-jwt "token-app-property" variable to value "host_cliam"
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::AuthnJwt::NoSuchFieldInToken: CONJ00081E
    """

  Scenario: Token identity configuration with empty secret, no identity in URL, error
    Given I issue a JWT token:
    """
    {
      "project-id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    Errors::Conjur::RequiredSecretMissing: CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/token-app-property
    """
