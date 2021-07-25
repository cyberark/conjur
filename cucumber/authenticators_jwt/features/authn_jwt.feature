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

  @sanity
  Scenario: ONYX-8598: Authenticator is not enabled
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
