Feature: JWT Authenticator - Status Check

  Checks status API of JWT authenticator. Status API should return error on each case of misconfiguration in
  authenticator or policy that can be found before authentication request.

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

      - !variable
        id: issuer

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

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
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I successfully set authn-jwt "issuer" variable to value "gitlab"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds

  Scenario: ONYX-9138: Signing key is not configured
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice
        annotations:
          description: Authentication service for JWT tokens, based on raw JWKs.

      - !variable
        id: token-app-property

      - !variable
        id: issuer

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

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
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I successfully set authn-jwt "issuer" variable to value "someIssuer"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00086E Signing key URI configuration is invalid"

  Scenario: Signing key is configured with jwks-uri and provider-uri
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
        id: provider-uri

      - !variable
        id: token-app-property

      - !variable
        id: issuer

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

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
    And I successfully set authn-jwt "provider-uri" variable to value "someProvider"
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I successfully set authn-jwt "issuer" variable to value "someIssuer"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00086E Signing key URI configuration is invalid"

  Scenario: ONYX-9142: User doesn't have permissions on webservice
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
    """
    And I am the super-user
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 403
    And the authenticator status check fails with error "CONJ00006E 'alice' does not have 'read' privilege on cucumber:webservice:conjur/authn-jwt/raw/status"

  Scenario: ONYX-9139: Non existing issuer, and existing Signing key
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
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds

  Scenario: ONYX-9140: Non existing issuer and Signing key
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice
        annotations:
          description: Authentication service for JWT tokens, based on raw JWKs.

      - !variable
        id: token-app-property

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

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
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00078E Issuer authenticator configuration is invalid"

  Scenario: ONYX-9141: Identity is configured but empty
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
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/token-app-property"

  Scenario: ONYX-9143: Status webservice does not exist
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

      - !group
          id: operators
          annotations:
            description: Group of users who can check the status of the authenticator

    - !user alice

    - !grant
      role: !group conjur/authn-jwt/raw/operators
      member:
      - !user alice
    """
    And I am the super-user
    And I successfully set authn-jwt jwks-uri variable with value of "myJWKs.json" endpoint
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00005E Webservice 'authn-jwt/raw/status' not found"

  Scenario: ONYX-9569: JWKS-uri is configured but empty
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
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/jwks-uri"

  Scenario: ONYX-9570: Provider-uri is configured but empty
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice
        annotations:
          description: Authentication service for JWT tokens, based on raw JWKs.

      - !variable
        id: provider-uri

      - !variable
        id: token-app-property

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

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
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/provider-uri"

  Scenario: ONYX-9571: Provider-uri is configured with bad value
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-jwt/raw
      body:
      - !webservice
        annotations:
          description: Authentication service for JWT tokens, based on raw JWKs.

      - !variable
        id: provider-uri

      - !variable
        id: token-app-property

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

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
    And I successfully set authn-jwt "provider-uri" variable to value "unknow-host.com"
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00011E Failed to discover Identity Provider"

  Scenario: ONYX-9572: JWKS-uri is configured with bad value
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
    And I successfully set authn-jwt "jwks-uri" variable to value "unknow-host.com"
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00079E Failed to extract hostname from URI 'unknow-host.com'"

  @sanity
  Scenario: ONYX-9516: Identify-path is configured but empty
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

      - !variable
        id: identity-path

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

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
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/identity-path>"

  @sanity
  Scenario: ONYX-9515: Valid status check, identify-path is configured with value
    Given I load a policy:
    """
    - !policy
      id: apps
      body:
      - !host myuser

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

      - !variable
        id: identity-path

      - !variable
        id: issuer

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

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
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I successfully set authn-jwt "identity-path" variable to value "apps"
    And I successfully set authn-jwt "issuer" variable to value "gitlab"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds
