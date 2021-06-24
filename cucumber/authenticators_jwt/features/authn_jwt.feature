Feature: JWT Authenticator - JWKs Basic sanity

  In this feature we define a JWT authenticator in policy and perform authentication
  with Conjur. In successful scenarios we will also define a variable and permit the host to
  execute it.

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

      - !group hosts

      - !permit
        role: !group hosts
        privilege: [ read, authenticate ]
        resource: !webservice

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am the super-user
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint
    And I successfully set authn-jwt "token-app-property" variable to value "host"

  Scenario: Authenticator is not enabled
    Given I have a "variable" resource called "test-variable"
    And I issue a JWT token:
    """
    {
      "user":"myapp",
      "project-id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with non-existing service ID
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00004E 'authn-jwt/non-existing' is not enabled
    """

  Scenario: Empty Token Given
    Given I have a "variable" resource called "test-variable"
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
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then it is a bad request
    And The following appears in the log after my savepoint:
    """
    CONJ00009E Field 'jwt' is missing or empty in request body
    """

  Scenario: Annotation with empty value
    Given I have a "variable" resource called "test-variable"
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/custom-claim:
    """
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00100E Annotation, 'custom-claim', is empty
    """

  Scenario: Host not in authenticator permitted group is denied
    Given I have a "variable" resource called "test-variable"
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/custom-claim:
    """
    And I issue a JWT token:
    """
    {
      "host":"not_premmited",
      "project-id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00007E 'host/not_premmited' not found
    """

  Scenario: Ignore invalid annotations from failing the test
    Given I have a "variable" resource called "test-variable"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw: invalid
        authn-jwt/raw/sub: valid
        authn-jwt: invalid
        authn-jwt/raw/namespace-id: valid
        authn-jwt/raw/sub/sub: invalid
        authn-jwt/raw/project-path: valid
        authn-jwt/raw2/sub: invalid
    """
    And I permit host "myapp" to "execute" it
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject",
      "sub": "valid",
      "namespace-id": "valid",
      "project-path": "valid"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And the HTTP response status code is 200
    And The following lines appear in the log after my savepoint:
    |                                                                     |
    |CONJ00048D Validating resource restriction on request: 'sub'         |
    |CONJ00048D Validating resource restriction on request: 'namespace-id'|
    |CONJ00048D Validating resource restriction on request: 'project-path'|
    |CONJ00045D Resource restrictions matched request                     |
    |CONJ00030D Resource restrictions validated                           |
    |CONJ00103D 'validate_restrictions' passed successfully               |
