Feature: JWT Authenticator - Status Check

  Scenario: A valid JWT status request
    Given I load a policy:
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

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

    - !host
      id: myapp
      annotations:
        authn-jwt/raw/project-id: myproject

    - !grant
      role: !group conjur/authn-jwt/raw/users
      member: !host myapp

    - !webservice
        id: status
        annotations:
          description: Status service to check that the authenticator is configured correctly

    - !group
        id: operators
        annotations:
          description: Group of users who can check the status of the authenticator

    - !permit
        role: !group operators
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-jwt/raw/operators
      member:
      - !user alice
    """
    And I am the super-user
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint
    And I successfully set authn-jwt token-app-property variable to value "user"
    And I login as "alice"
    And I have a "variable" resource called "test-variable"
    And I permit host "myapp" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds