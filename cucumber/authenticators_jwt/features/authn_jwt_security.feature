@authenticators_jwt
Feature: JWT Authenticator - Security

  Tests checking that JWT authenticator stands against different attacks and security risks.
  Checking different authenticators with different algorithms signing the jwt token.

  Background:
    Given I load a policy:
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
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I have a "variable" resource called "test-variable"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it

  @negative @acceptance
  Scenario: ONYX-8851: None algorithm is unacceptable, 401 ERROR
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint
    And I issue none alg JWT token:
    """
    {
      "namespace_id": "7432059",
      "job_id": "1364141408"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00048I Authentication Error: #<Errors::Authentication::Jwt::RequestBodyMissingJWTToken: CONJ00077E The request body does not contain JWT token>
    """

  @negative @acceptance
  Scenario: ONYX-8852: Test algorithm substitution attack, 401 ERROR
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint
    And I issue HMAC JWT token:
    """
    {
      "namespace_id": "7432059",
      "job_id": "1364141408"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::IncorrectAlgorithm: Expected a different algorithm>')>
    """

  @acceptance
  Scenario Outline: ONYX-8858: Algorithms sanity
    Given I initialize remote JWKS endpoint with file "ONYX-8858-<alg>" and alg "<alg>"
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/ONYX-8858-<alg>/<alg>" in service "raw"
    And I am using file "ONYX-8858-<alg>" and alg "<alg>" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is <code>
    And The following appears in the log after my savepoint:
    """
    <log>
    """
    Examples:
      | alg   | code | log                                                                                                                          |
      | RS256 | 200  | cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw |
      | RS384 | 200  | cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw |
      | RS512 | 200  | cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw |
      | ES256 | 401  | CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::IncorrectAlgorithm: Expected a different algorithm>')>             |
      | ES384 | 401  | CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::IncorrectAlgorithm: Expected a different algorithm>')>             |
      | ES512 | 401  | CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::IncorrectAlgorithm: Expected a different algorithm>')>             |
      | HS256 | 401  | CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::IncorrectAlgorithm: Expected a different algorithm>')>             |
      | HS384 | 401  | CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::IncorrectAlgorithm: Expected a different algorithm>')>             |
      | HS512 | 401  | CONJ00035E Failed to decode token (3rdPartyError ='#<JWT::IncorrectAlgorithm: Expected a different algorithm>')>             |
