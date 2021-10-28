Feature: JWT Authenticator - Fetch identity from decoded token

  Tests checking the fetch of identity from JWT token using these configurations from policy:
  * 'token-app-property' - define claim in JWT token that holds the identity
  * 'identity-path' - prefix of the host connecting with JWT authenticator

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
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp

    - !host
      id: some_policy/sub_policy/host_test_from_token
      annotations:
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host some_policy/sub_policy/host_test_from_token

    - !host
      id: some_policy/host_test_from_token
      annotations:
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host some_policy/host_test_from_token
    """
    And I am the super-user
    And I have a "variable" resource called "test-variable"
    And I initialize remote JWKS endpoint with file "identity-from-decoded-token" and alg "RS256"
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/identity-from-decoded-token/RS256" in service "raw"

  @sanity
  Scenario: ONYX-8820: A valid JWT token with identity in the token
    Given I successfully set authn-jwt "token-app-property" variable to value "host"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I am using file "identity-from-decoded-token" and alg "RS256" for remotely issue token:
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

  @sanity
  Scenario: ONYX-9522: User as Token identity is not supported, error
    And I successfully set authn-jwt "token-app-property" variable to value "host"
    Given I extend the policy with:
    """
    - !user
      id: myuser
      annotations:
        authn-jwt/raw/custom-claim:

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !user myuser
    """
    And I am using file "identity-from-decoded-token" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp2",
      "project-id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00007E 'host/myapp2' not found
    """

  Scenario: ONYX-8825: Token identity configuration not matching any claim, error
    Given I am using file "identity-from-decoded-token" and alg "RS256" for remotely issue token:
    """
    {
      "project-id": "myproject",
      "more-claims":
      {
        "host_claim":"myapp"
      }
    }
    """
    And I successfully set authn-jwt "token-app-property" variable to value "host_claim"
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00081E 'host_claim' field not found in the token
    """

  Scenario: ONYX-8824: Token identity configuration with empty secret, no identity in URL, error
    Given I am using file "identity-from-decoded-token" and alg "RS256" for remotely issue token:
    """
    {
      "project-id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/token-app-property
    """

  @sanity
  Scenario: ONYX-9524: Host with delimiter as Token identity, identity-path configured, 200 ok
    Given I have a "variable" resource called "test-variable"
    And I successfully set authn-jwt "token-app-property" variable to value "host_claim"
    And I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: identity-path
    """
    And I successfully set authn-jwt "identity-path" variable to value "some_policy/"
    And I permit host "some_policy/sub_policy/host_test_from_token" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I am using file "identity-from-decoded-token" and alg "RS256" for remotely issue token:
    """
    {
      "host_claim":"sub_policy/host_test_from_token",
      "project-id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then host "some_policy/sub_policy/host_test_from_token" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:some_policy/sub_policy/host_test_from_token successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @sanity
  Scenario: ONYX-9523: Host without delimiter as Token identity, identity-path configured, 200 ok
    Given I have a "variable" resource called "test-variable"
    And I successfully set authn-jwt "token-app-property" variable to value "host_claim"
    And I extend the policy with:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !variable
        id: identity-path
    """
    And I successfully set authn-jwt "identity-path" variable to value "some_policy/"
    And I permit host "some_policy/host_test_from_token" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I am using file "identity-from-decoded-token" and alg "RS256" for remotely issue token:
    """
    {
      "host_claim":"host_test_from_token",
      "project-id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then host "some_policy/host_test_from_token" has been authorized by Conjur
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    And The following appears in the log after my savepoint:
    """
    cucumber:host:some_policy/host_test_from_token successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """
