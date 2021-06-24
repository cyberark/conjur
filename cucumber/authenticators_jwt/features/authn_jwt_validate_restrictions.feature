Feature: JWT Authenticator - Validate restrictions
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
    """
    And I am the super-user
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint

  Scenario: Generals annotations with valid values, one annotation with valid service and valid value, one annotation with invalid service and valid value, 200 OK
    Given I have a "variable" resource called "test-variable"
    And I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/project-id: myproject
        authn-jwt/aud: myaud
        authn-jwt/raw/project-id: myproject
        authn-jwt/invalid-service/aud: myaud

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject",
      "aud": "myaud"
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

  Scenario: General annotation and without service specific annotations, 401 Error
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/project-id: myproject
        authn-jwt/aud: myaud

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject",
      "aud": "myaud"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00099E Role must have at least one relevant annotation
    """

  Scenario: General annotations with valid values, annotation with correct service and valid value and annotation with correct service and wrong value, 401 Error
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/project-id: myproject
        authn-jwt/aud: myaud
        authn-jwt/raw/project-id: myproject
        authn-jwt/raw/aud: wrong-aud

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject",
      "aud": "myaud"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'aud' does not match with the corresponding value in the request
    """

  Scenario: Host without annotations, 401 Error
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    Given I extend the policy with:
    """
    - !host
      id: myapp

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "myproject",
      "aud": "myaud"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00099E Role must have at least one relevant annotation
    """

  Scenario: Validate multiple annotations with incorrect values but one, 401 Error
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: invalid
        authn-jwt/raw/project-path: invalid
        authn-jwt/raw/project-id: myproject
        authn-jwt/raw/aud: invalid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "sub": "sub",
      "project-path":"path",
      "project-id": "myproject",
      "aud": "myaud"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction
    """

  Scenario: Validate multiple annotations with incorrect, 401 Error
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: invalid
        authn-jwt/raw/project-path: invalid
        authn-jwt/raw/aud: invalid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "sub": "sub",
      "project-path":"path",
      "aud": "myaud"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction
    """

  Scenario: Non existing field annotation, 401 Error
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/non-existing-field: invalid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I issue a JWT token:
    """
    {
      "host":"myapp"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00084E Claim 'non-existing-field' is missing from JWT token.
    """
