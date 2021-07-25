Feature: JWT Authenticator - Input Validation

  Check scenarios with authentication request

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

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

    - !user
      id: myuser
      annotations:
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/users
      member: !user myuser
    """
    And I am the super-user
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint

  @sanity
  Scenario: ONYX-8594: Empty Token Given, 401 Error
    Given I save my place in the log file
    And I issue empty JWT token
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00085E Token is empty or not found.
    """

  @sanity
  Scenario: ONYX-8594: Invalid Token Given, 401 Error
    Given I save my place in the log file
    When I authenticate with string that is not token not-token-string-this-is-ivalid-token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00077E The request body does not contain JWT token
    """

  @sanity
  Scenario: ONYX-8594: No Token Given, 400 Error
    Given I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 400
    And The following appears in the log after my savepoint:
    """
    CONJ00009E Field 'jwt' is missing or empty in request body
    """

  Scenario: ONYX-8579: URL not includes service-id, includes correct account
    Given I save my place in the log file
    And I issue a JWT token:
    """
    {
      "project-id": "myproject"
    }
    """
    When I authenticate via authn-jwt without service id but with myuser account in url
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00004E 'authn-jwt/myuser' is not enabled
    """

  Scenario: ONYX-8579: URL includes valid service id, wrong account name
    Given I save my place in the log file
    And I issue a JWT token:
    """
    {
      "project-id": "myproject"
    }
    """
    When I authenticate via authn-jwt with wrong-account account in url
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00007E 'wrong-account' not found
    """

  Scenario: ONYX-8579: URL includes wrong service id, correct account name
    Given I save my place in the log file
    And I issue a JWT token:
    """
    {
      "project-id": "myproject"
    }
    """
    When I authenticate via authn-jwt using given wrong-id service ID and with myuser account in url
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00004E 'authn-jwt/wrong-id' is not enabled>
    """

