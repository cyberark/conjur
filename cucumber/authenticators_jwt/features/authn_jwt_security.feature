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
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I have a "variable" resource called "test-variable"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it

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

  Scenario Outline: ONYX-8858: Token Signed by RSA, 200 OK
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint
    And I issue an "<alg>" algorithm RSA JWT token:
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
    Examples:
      | alg |
      | RS256 |
      | RS384 |
      | RS512 |

