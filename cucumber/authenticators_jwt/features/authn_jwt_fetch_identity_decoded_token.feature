@authenticators_jwt
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
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host myapp

    - !host
      id: some_policy/sub_policy/host_test_from_token
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host some_policy/sub_policy/host_test_from_token

    - !host
      id: some_policy/host_test_from_token
      annotations:
        authn-jwt/raw/project_id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/hosts
      member: !host some_policy/host_test_from_token
    """
    And I am the super-user
    And I have a "variable" resource called "test-variable"
    And I initialize remote JWKS endpoint with file "identity-from-decoded-token" and alg "RS256"
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/identity-from-decoded-token/RS256" in service "raw"

  @sanity
  @smoke
  Scenario: ONYX-8820: A valid JWT token with identity in the token
    Given I successfully set authn-jwt "token-app-property" variable to value "host"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I am using file "identity-from-decoded-token" and alg "RS256" for remotely issue token:
    """
    {
      "host":"myapp",
      "project_id": "myproject"
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
  @negative @acceptance
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
      "project_id": "myproject"
    }
    """
    And I save my place in the log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00007E 'host/myapp2' not found
    """

  @negative @acceptance
  Scenario: ONYX-8825: Token identity configuration not matching any claim, error
    Given I am using file "identity-from-decoded-token" and alg "RS256" for remotely issue token:
    """
    {
      "project_id": "myproject",
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

  @negative @acceptance
  Scenario: ONYX-8824: Token identity configuration with empty secret, no identity in URL, error
    Given I am using file "identity-from-decoded-token" and alg "RS256" for remotely issue token:
    """
    {
      "project_id": "myproject"
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
  @acceptance
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
      "project_id": "myproject"
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
  @acceptance
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
      "project_id": "myproject"
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

  @sanity
  @acceptance
  Scenario: ONYX-13707: Token-app-property from nested claim
    Given I successfully set authn-jwt "token-app-property" variable to value "account/project/id"
    And I am using file "identity-from-decoded-token" and alg "RS256" for remotely issue token:
    """
    {
      "account":
      {
        "project":
        {
          "id": "myapp"
        }
      },
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then host "myapp" has been authorized by Conjur
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  @negative @acceptance
  Scenario: ONYX-13711: Token-app-property does not accept array reference
    Given I successfully set authn-jwt "token-app-property" variable to value "account[0]/project/id"
    And I am using file "identity-from-decoded-token" and alg "RS256" for remotely issue token:
    """
    {
      "account":
      [
        {
          "project":
          {
            "id": "myapp"
          }
        }
      ],
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00117E Failed to parse 'token-app-property' value. Error: '#<Errors::Authentication::AuthnJwt::InvalidClaimPath: CONJ00116E
    """

  @negative @acceptance
  Scenario: ONYX-13713: Token-app-property does not accept array reference
    Given I successfully set authn-jwt "token-app-property" variable to value "account/projects"
    And I am using file "identity-from-decoded-token" and alg "RS256" for remotely issue token:
    """
    {
      "account":
      {
        "projects":
        [
          "project_1",
          "project_2"
        ]
      },
      "project_id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00118E 'account/projects' value in token has type 'Array'. An identity must be a String.
    """
