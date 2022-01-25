@authenticators_jwt
Feature: JWT Authenticator - Input Validation

  Check scenarios with authentication request

  Background:
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

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
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/users
      member: !user myuser
    """
    And I am the super-user
    And I initialize remote JWKS endpoint with file "authn-jwt-input-validation" and alg "RS256"
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-input-validation/RS256" in service "raw"

  @sanity
  @negative @acceptance
  Scenario: ONYX-8594: Empty Token Given, 401 Error
    Given I save my place in the log file
    And I am using file "authn-jwt-input-validation" and alg "RS256" for remotely issue non exp token:
    """
    {}
    """
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00085E Token is empty or not found.
    """

  @sanity
  @negative @acceptance
  Scenario: ONYX-8594: Invalid Token Given, 401 Error
    Given I save my place in the log file
    When I authenticate with string that is not token not-token-string-this-is-ivalid-token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00077E The request body does not contain JWT token
    """

  @sanity
  @negative @acceptance
  Scenario: ONYX-8594: No Token Given, 400 Error
    Given I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 400
    And The following appears in the log after my savepoint:
    """
    CONJ00009E Field 'jwt' is missing or empty in request body
    """

  @negative @acceptance
  Scenario: ONYX-8579: URL not includes service-id, includes correct account
    Given I save my place in the log file
    And I am using file "authn-jwt-input-validation" and alg "RS256" for remotely issue non exp token:
    """
    {
      "project_id": "myproject"
    }
    """
    When I authenticate via authn-jwt without service id but with myuser account in url
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00004E 'authn-jwt/myuser' is not enabled
    """

  @negative @acceptance
  Scenario: ONYX-8579: URL includes valid service id, wrong account name
    Given I save my place in the log file
    And I am using file "authn-jwt-input-validation" and alg "RS256" for remotely issue token:
    """
    {
      "project_id": "myproject"
    }
    """
    When I authenticate via authn-jwt with wrong-account account in url
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00007E 'wrong-account' not found
    """

  @negative @acceptance
  Scenario: ONYX-8579: URL includes wrong service id, correct account name
    Given I save my place in the log file
    And I am using file "authn-jwt-input-validation" and alg "RS256" for remotely issue non exp token:
    """
    {
      "project_id": "myproject"
    }
    """
    When I authenticate via authn-jwt using given wrong-id service ID and with myuser account in url
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00004E 'authn-jwt/wrong-id' is not enabled>
    """
