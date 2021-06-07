Feature: JWT Authenticator - JWKs Basic sanity

  In this feature we define a JWT authenticator in policy and perform authentication
  with Conjur. In successful scenarios we will also define a variable and permit the host to
  execute it.

  Background:
    Given I initialize JWKs endpoint with file "myJWKs.json"
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
    And I successfully set authn-jwt token-app-property variable to value "user"

  Scenario: A valid JWT token with identity in the token
    Given I have a "variable" resource called "test-variable"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I issue a JWT token:
    """
    {
      "user":"host/myapp",
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

  Scenario: Empty Token Given
    Given I have a "variable" resource called "test-variable"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I save my place in the log file
    And I issue empty JWT token
    When I authenticate via authn-jwt with the JWT token
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    CONJ00085E Token is empty or not found.
    """

  Scenario: No Token Given
    Given I have a "variable" resource called "test-variable"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    CONJ00009E Field 'jwt' is missing or empty in request body
    """
