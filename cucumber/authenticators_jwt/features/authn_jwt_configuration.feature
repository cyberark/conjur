Feature: JWT Authenticator - Configuration Check
  Background:
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I have a "variable" resource called "test-variable"

  Scenario: Webservice is missing in Authenticator policy
    And I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: jwks-uri

      - !variable
        id: token-app-property

      - !group users
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
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I issue a JWT token:
    """
    {
      "user":"host/myapp",
      "project-id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00005E Webservice 'authn-jwt/raw' not found
    """

  Scenario: Webservice with read and no authenticate permission in authenticator policy
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
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I issue a JWT token:
    """
    {
      "user":"host/myapp",
      "project-id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 403
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotAuthorizedOnResource: CONJ00006E
    """

  Scenario: Both provider-uri and jwks-uri are configured
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
        id: provider-uri

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
    And I successfully set authn-jwt "jwks-uri" variable to value "jwks uri placehodlder"
    And I successfully set authn-jwt "provider-uri" variable to value "provider uri placeholder"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I issue a JWT token:
    """
    {
      "user":"host/myapp",
      "project-id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00086E Signing key URI configuration is invalid
    """
