Feature: JWT Authenticator - Token Schema

  Tests checking mandatory claims and claims mapping

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
    And I have a "variable" resource called "test-variable"
    And I successfully set authn-jwt "token-app-property" variable to value "host"

  Scenario: ONYX-10471 - Mandatory Claims Without Claims Mapping. Single mandatory claim - 200 OK
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: mandatory-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mandatory-claims" variable to value "ref"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I issue a JWT token:
    """
    {
      "ref":"valid",
      "host":"myapp"
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

  Scenario: ONYX-10471 - Mandatory Claims Without Claims Mapping. Two mandatory claims - 200 OK
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: mandatory-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid
        authn-jwt/raw/sub: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mandatory-claims" variable to value "ref,sub"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I issue a JWT token:
    """
    {
      "ref":"valid",
      "sub":"valid",
      "host":"myapp"
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

  Scenario: ONYX-10759 - Mandatory Claims Without Claims Mapping. Single mandatory claim and wrong annotation - 401 Error
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: mandatory-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mandatory-claims" variable to value "ref"
    And I issue a JWT token:
    """
    {
      "ref":"valid",
      "host":"myapp"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00057E Role does not have the required constraints: '["ref"]'>
    """

  Scenario: ONYX-10760 - Mandatory Claims Without Claims Mapping. Single mandatory claim but not in token - 401 Error
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: mandatory-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mandatory-claims" variable to value "ref"
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
    CONJ00084E Claim 'ref' is missing from JWT token.
    """

  Scenario Outline: ONYX-10470 - Standard claim in mandatory claims - 401 Error
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: mandatory-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mandatory-claims" variable to value "<claims>"
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
    CONJ00105E Failed to validate claim, claim name '<err>' is in denylist '["iss", "exp", "nbf", "iat", "jti", "aud"]'
    """
    Examples:
    | claims        | err |
    |   iss         |  iss   |
    |   exp, iss    |  exp   |
    |   exp, branch |  exp   |

  Scenario Outline: ONYX-10857 - Standard claim in annotation - 401 Error
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/<claim>: valid

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
    CONJ00069E Role can't have one of these none permitted restrictions '["<claim>"]'>
    """
    Examples:
    | claim   |
    |   iat   |

  Scenario: ONYX-10860 - Mandatory claims configured but not populated - 401 Error
    Given I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: mandatory-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I issue a JWT token:
    """
    {
      "ref":"valid",
      "host":"myapp"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
     CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/mandatory-claims
    """

  Scenario: ONYX-10891 - Complex Case - Adding Mandatory Claim after host configuration
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I issue a JWT token:
    """
    {
      "sub":"valid",
      "ref":"valid",
      "host":"myapp"
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
    When I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: mandatory-claims
    """
    And I successfully set authn-jwt "mandatory-claims" variable to value "ref"
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00057E Role does not have the required constraints: '["ref"]'>
    """
    When I replace the "root" policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: mandatory-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """
