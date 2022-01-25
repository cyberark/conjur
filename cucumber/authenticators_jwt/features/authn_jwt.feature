@authenticators_jwt
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
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am the super-user
    And I initialize remote JWKS endpoint with file "authn-jwt-general" and alg "RS256"
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-general/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "host"

  @sanity
  @negative @acceptance
  Scenario: ONYX-8598: Authenticator is not enabled
    Given I have a "variable" resource called "test-variable"
    And I am using file "authn-jwt-general" and alg "RS256" for remotely issue token:
    """
    {
      "user":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with non-existing service ID
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00004E 'authn-jwt/non-existing' is not enabled
    """

  @negative @acceptance
  Scenario: ONYX-8821: Host that doesn't exist is denied
    Given I am using file "authn-jwt-general" and alg "RS256" for remotely issue token:
    """
    {
      "host":"non_existing",
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00007E 'host/non_existing' not found
    """
    And The following appears in the audit log after my savepoint:
    """
    cucumber:host:non_existing failed to authenticate with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """
