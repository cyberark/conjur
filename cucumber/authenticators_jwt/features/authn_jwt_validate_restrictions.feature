@authenticators_jwt
Feature: JWT Authenticator - Validate restrictions

  Tests to check that host annotations are validated correctly in jwt authenticator. Focusing on checking that only the vendor related annotations are being checked.

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
    """
    And I am the super-user
    And I initialize remote JWKS endpoint with file "authn-jwt-validate-restrictions" and alg "RS256"
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-validate-restrictions/RS256" in service "raw"

  @acceptance
  Scenario: ONYX-9069: Generals annotations with valid values, one annotation with valid service and valid value, one annotation with invalid service and valid value, 200 OK
    Given I have a "variable" resource called "test-variable"
    And I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/project_id: myproject
        authn-jwt/aud: myaud
        authn-jwt/raw/project_id: myproject
        authn-jwt/raw/additional_data/group_name: mygroup
        authn-jwt/invalid-service/aud: myaud

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I am using file "authn-jwt-validate-restrictions" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject",
      "additional_data":
      {
        "group_name": "mygroup",
        "group_id": "group21",
        "team_name": "myteam",
        "team_id": "team76"
      },
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

  @negative @acceptance
  Scenario: ONYX-9112: General annotation and without service specific annotations, 401 Error
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/project_id: myproject
        authn-jwt/aud: myaud

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am using file "authn-jwt-validate-restrictions" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject",
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

  @negative @acceptance
  Scenario: ONYX-9070: General annotations with valid values, annotation with correct service and valid value and annotation with correct service and wrong value, 401 Error
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/project_id: right-project-id
        authn-jwt/ref: right-ref
        authn-jwt/raw/project_id: right-project-id
        authn-jwt/raw/ref: wrong-ref

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am using file "authn-jwt-validate-restrictions" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "right-project-id",
      "ref": "right-ref"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction 'ref' does not match with the corresponding value in the request
    """

  @negative @acceptance
  Scenario: ONYX-9068: Host without annotations, 401 Error
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    Given I extend the policy with:
    """
    - !host
      id: myapp

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am using file "authn-jwt-validate-restrictions" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "valid-project-id",
      "ref": "valid-ref"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00099E Role must have at least one relevant annotation
    """

  @negative @acceptance
  Scenario: ONYX-8737: Validate multiple annotations with incorrect values but one, 401 Error
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: invalid-sub
        authn-jwt/raw/project_path: invalid-project-path
        authn-jwt/raw/project_id: valid-project-id
        authn-jwt/raw/ref: invalid-ref

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am using file "authn-jwt-validate-restrictions" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "sub": "valid-sub",
      "project_path":"valid-project-path",
      "project_id": "valid-project-id",
      "ref": "valid-ref"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction
    """

  @negative @acceptance
  Scenario: ONYX-8736: Validate multiple annotations with incorrect, 401 Error
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: invalid-sub
        authn-jwt/raw/project_path: invalid-project-path
        authn-jwt/raw/ref: invalid-ref

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am using file "authn-jwt-validate-restrictions" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "sub": "valid-sub",
      "project_path":"valid-project-path",
      "ref": "valid-ref"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00049E Resource restriction
    """

  @negative @acceptance
  Scenario: ONYX-9113: Non existing field annotation, 401 Error
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/non_existing_field: invalid

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am using file "authn-jwt-validate-restrictions" and alg "RS256" for remotely issue token:
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
    CONJ00084E Claim 'non_existing_field' is missing from JWT token.
    """

  @sanity
  @negative @acceptance
  Scenario: ONYX-8734: Annotation with empty value
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/custom_claim:

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I am using file "authn-jwt-validate-restrictions" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00100E Annotation, 'custom_claim', is empty
    """

  @sanity
  @acceptance
  Scenario: ONYX-8735: Ignore invalid annotations
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw: invalid
        authn-jwt/raw/sub: valid-sub
        authn-jwt: invalid
        authn-jwt/raw/namespace_id: valid-namespace-id
        authn-jwt/raw/project_path: valid-project-path
        authn-jwt/raw2/sub: invalid-sub

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    And I am using file "authn-jwt-validate-restrictions" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "valid-project-id",
      "sub": "valid-sub",
      "namespace_id": "valid-namespace-id",
      "project_path": "valid-project-path"
    }
    """
    And I have a "variable" resource called "test-variable"
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I permit host "myapp" to "execute" it
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And the HTTP response status code is 200
    And The following lines appear in the log after my savepoint:
      |                                                                     |
      |CONJ00048D Validating resource restriction on request: 'sub'         |
      |CONJ00048D Validating resource restriction on request: 'namespace_id'|
      |CONJ00048D Validating resource restriction on request: 'project_path'|
      |CONJ00045D Resource restrictions matched request                     |
      |CONJ00030D Resource restrictions validated                           |
      |CONJ00103D 'validate_restrictions' passed successfully               |

  @negative @acceptance
  Scenario: ONYX-13722: Annotation with invalid claim path format, 401 Error
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    Given I extend the policy with:
    """
    - !host
      id: myapp
      annotations:
        authn-jwt/raw/sub: valid-sub
        authn-jwt/raw/actions[0]: GET

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp
    """
    And I am using file "authn-jwt-validate-restrictions" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "sub": "valid-sub",
      "actions": ["GET", "POST"]
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00119E Restriction 'actions[0]' is invalid and not representing claim path in the token
    """
