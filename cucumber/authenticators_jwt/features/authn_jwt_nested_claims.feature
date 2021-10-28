Feature: JWT Authenticator - nested claims support

  In this feature we check all aspects of nested claims support

  Background:
    Given I initialize JWKS endpoint with file "myJWKs.json"
    And I load a policy:
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
    """
    And I am the super-user
    And I initialize remote JWKS endpoint with file "authn-jwt-general" and alg "RS256"
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-general/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "host"

  @sanity
  Scenario: ONYX-13707: Token-app-property from nested claim
    Given I successfully set authn-jwt "token-app-property" variable to value "account/project/id"
    And I am using file "authn-jwt-general" and alg "RS256" for remotely issue token:
    """
    {
      "account":
      {
        "project":
        {
          "id": "myapp"
        }
      },
      "project-id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then host "myapp" has been authorized by Conjur
    And The following appears in the log after my savepoint:
    """
    cucumber:host:myapp successfully authenticated with authenticator authn-jwt service cucumber:webservice:conjur/authn-jwt/raw
    """

  Scenario: ONYX-13711: Token-app-property does not accept array reference
    Given I successfully set authn-jwt "token-app-property" variable to value "account[0]/project/id"
    And I am using file "authn-jwt-general" and alg "RS256" for remotely issue token:
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
      "project-id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00117E Failed to parse `token-app-property` claim path: 'account[0]/project/id'. The claim path is in an invalid format.
    """

  Scenario: ONYX-13713: Token-app-property does not accept array reference
    Given I successfully set authn-jwt "token-app-property" variable to value "account/projects"
    And I am using file "authn-jwt-general" and alg "RS256" for remotely issue token:
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
      "project-id": "myproject"
    }
    """
    And I save my place in the audit log file
    When I authenticate via authn-jwt with the JWT token
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    CONJ00118E 'account/projects' value in token has type Array. Only string value can be an identity.
    """
