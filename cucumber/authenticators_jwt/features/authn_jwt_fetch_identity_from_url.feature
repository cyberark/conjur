@authenticators_jwt
Feature: JWT Authenticator - Fetch identity from URL

  Tests for fetching identity from URL of the JWT authentication request.

  Background:
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice

      - !variable
        id: jwks-uri

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

    - !host
      id: some_policy/host_test_from_url
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host some_policy/host_test_from_url

    - !user
      id: user_test_from_url@some_policy
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !user user_test_from_url@some_policy

    - !user
      id: user_test_from_url
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !user user_test_from_url
    """
    And I am the super-user
    And I initialize remote JWKS endpoint with file "identity-from-url" and alg "RS256"
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/identity-from-url/RS256" in service "raw"

  @acceptance
  Scenario: ONYX-9520: User send in URL, user not in root, 200 ok
    Given I have a "variable" resource called "test-variable"
    And I permit user "user_test_from_url@some_policy" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I am using file "identity-from-url" and alg "RS256" for remotely issue token:
    """
    {
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with user_test_from_url%40some_policy account in url
    Then user "user_test_from_url@some_policy" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:user:user_test_from_url@some_policy successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @acceptance
  Scenario: ONYX-9519: User send in URL, user in root, 200 ok
    Given I have a "variable" resource called "test-variable"
    And I permit user "user_test_from_url" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I am using file "identity-from-url" and alg "RS256" for remotely issue token:
    """
    {
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with user_test_from_url account in url
    Then user "user_test_from_url" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:user:user_test_from_url successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @sanity
  @acceptance
  Scenario: ONYX-9521: Host send in URL, host not in root, 200 ok
    Given I have a "variable" resource called "test-variable"
    And I permit host "some_policy/host_test_from_url" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I am using file "identity-from-url" and alg "RS256" for remotely issue token:
    """
    {
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with host%2Fsome_policy%2Fhost_test_from_url account in url
    Then host "some_policy/host_test_from_url" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:some_policy/host_test_from_url successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @acceptance
  Scenario: ONYX-9518: Host send in URL, host in root, 200 ok
    Given I have a "variable" resource called "test-variable"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I am using file "identity-from-url" and alg "RS256" for remotely issue token:
    """
    {
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with host%2Fmyapp account in url
    Then host "myapp" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @negative @acceptance
  Scenario: ONYX-8821: Host taken from URL but not defined in conjur, error
    Given I am using file "identity-from-url" and alg "RS256" for remotely issue token:
    """
    {
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with invalid_host account in url
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00007E 'invalid_host' not found
    """

  @acceptance
  Scenario: ONYX-9517: Host send in URL, host not in root, Identify-path with empty value is ignored, 200 ok
    Given I have a "variable" resource called "test-variable"
    And I permit host "some_policy/host_test_from_url" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I update the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: identity-path
    """
    And I am using file "identity-from-url" and alg "RS256" for remotely issue token:
    """
    {
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with host%2Fsome_policy%2Fhost_test_from_url account in url
    Then host "some_policy/host_test_from_url" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:some_policy/host_test_from_url successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """
