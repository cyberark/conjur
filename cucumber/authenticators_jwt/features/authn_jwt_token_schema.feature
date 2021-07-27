Feature: JWT Authenticator - Token Schema

  Tests checking enforced claims and claims mapping

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

  @sanity
  Scenario: ONYX-10471 - enforced Claims Without Claims Mapping. Single enforced claim - 200 OK
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "ref"
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

  Scenario: ONYX-10471 - enforced Claims Without Claims Mapping. Two enforced claims - 200 OK
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid-ref
        authn-jwt/raw/sub: valid-sub

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "ref,sub"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I issue a JWT token:
    """
    {
      "ref":"valid-ref",
      "sub":"valid-sub",
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

  Scenario: ONYX-10759 - enforced Claims Without Claims Mapping. Single enforced claim and wrong annotation - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "ref"
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

  Scenario: ONYX-10760 - enforced Claims Without Claims Mapping. Single enforced claim but not in token - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "ref"
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

  Scenario Outline: ONYX-10470 - Standard claim in enforced claims - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "<claims>"
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
    CONJ00069E Role can't have standard claim or a mapped claim
    """
    Examples:
    | claim   |
    |   iat   |

  Scenario: ONYX-10860 - Enforced claims configured but not populated - 401 Error
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

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
     CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/enforced-claims
    """

  @sanity
  Scenario: ONYX-10891 - Complex Case - Adding Enforced Claim after host configuration
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: valid-sub

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I issue a JWT token:
    """
    {
      "sub":"valid-sub",
      "ref":"valid-ref",
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
    - !variable conjur/authn-jwt/raw/enforced-claims
    """
    And I successfully set authn-jwt "enforced-claims" variable to value "ref"
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00057E Role does not have the required constraints: '["ref"]'>
    """
    When I replace the "root" policy with:
    """
    - !variable conjur/authn-jwt/raw/enforced-claims

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

  @sanity
  Scenario: ONYX-10472 Unrelated mapping
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project-id: valid-project
        authn-jwt/raw/namespace-id: valid-namespace

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "branch:ref"
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "valid-project",
      "namespace-id": "valid-namespace"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 200
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @sanity
  Scenario: ONYX-10473 Mapping claims with subsequent annotation
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims
    
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project-id: valid-project
        authn-jwt/raw/branch: valid-branch

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "branch:ref"
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "project-id": "valid-project",
      "ref": "valid-branch"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 200
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario: ONYX-10889 Complex Case - Adding Mapping after host configuration
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/ref: valid-branch

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "ref": "valid-branch"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then host "myapp" has been authorized by Conjur
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """
    When I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "branch:ref"
    And I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    Role can't have standard claim or a mapped claim
    """

  @sanity
  Scenario: ONYX-10705: enforced Claims and Mappings exist and host annotation are correct
    Given I extend the policy with:
    """
    - !variable conjur/authn-jwt/raw/mapping-claims
    - !variable conjur/authn-jwt/raw/enforced-claims

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/branch: valid-branch

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "mapping-claims" variable to value "branch:ref"
    And I successfully set authn-jwt "enforced-claims" variable to value "ref"
    And I issue a JWT token:
    """
    {
      "host":"myapp",
      "ref": "valid-branch"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 200
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """


