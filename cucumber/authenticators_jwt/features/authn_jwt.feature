Feature: JWT Authenticator - JWKs Basic sanity

  In this feature we define a JWT authenticator in policy and perform authentication
  with Conjur. In successful scenarios we will also define a variable and permit the host to
  execute it.

  Background:
    Given I initialize JWKs endpoint with file "first.json"
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
    And I successfully set authn-jwt jwks-uri variable with value of "first.json" endpoint
    And I successfully set authn-jwt token-app-property variable to value "user"

  Scenario: A valid JWT token with identity in the token
    Given I have a "variable" resource called "test-variable"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I issue a JWT token using key "first.json"::
    """
    {
      "user":"host/myapp",
      "project-id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token issued by "first.json" key
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario: Update jwks-uri dynamically
    Given I successfully set authn-jwt jwks-uri variable with value of "NotFound.json" endpoint
    And I issue a JWT token using key "first.json"::
    """
    {
      "user":"host/myapp",
      "project-id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token issued by "first.json" key
    Then it is unauthorized
    And The following appears in the audit log after my savepoint:
    """
    CONJ00185E
    """

    Given I initialize JWKs endpoint with file "second.json"
    And I successfully set authn-jwt jwks-uri variable with value of "second.json" endpoint
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token issued by "first.json" key
    Then it is unauthorized
    And The following appears in the audit log after my savepoint:
    """
    CONJ00035E
    """

    Given I successfully set authn-jwt jwks-uri variable with value of "first.json" endpoint
    When I authenticate via authn-jwt with the JWT token issued by "first.json" key
    Then host "myapp" has been authorized by Conjur
