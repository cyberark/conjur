@authenticators_jwt
Feature: JWT Authenticator - Status Check

  Checks status API of JWT authenticator. Status API should return error on each case of misconfiguration in
  authenticator or policy that can be found before authentication request.

  Background:
    Given I initialize remote JWKS endpoint with file "authn-jwt-configuration" and alg "RS256"

  @sanity
  @smoke
  Scenario: ONYX-9122: A valid JWT status request, 200 OK
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

      - !variable
        id: audience

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
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "kubernetes.io/user"
    And I successfully set authn-jwt "issuer" variable to value "gitlab"
    And I successfully set authn-jwt "audience" variable to value "conjur"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds

  @negative @acceptance
  Scenario: ONYX-9138: Signing key is not configured, 500 Error
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
    And the authenticator status check fails with error "CONJ00122E Invalid signing key settings: One of the following must be defined: jwks-uri, public-keys, or provider-uri"

  @negative @acceptance
  Scenario: Signing key is configured with jwks-uri and provider-uri, 500 Error
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
    And the authenticator status check fails with error "CONJ00122E Invalid signing key settings: jwks-uri and provider-uri cannot be defined simultaneously"

  @negative @acceptance
  Scenario: ONYX-9142: User doesn't have permissions on webservice, 403 Error
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

  @acceptance @acceptance
  Scenario: ONYX-9139: Non existing issuer, and existing Signing key, 200 OK
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
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds

  @negative @acceptance
  Scenario: ONYX-9140: Non existing issuer and Signing key, 500 Error
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
    And the authenticator status check fails with error "CONJ00122E Invalid signing key settings: One of the following must be defined: jwks-uri, public-keys, or provider-uri"

  @negative @acceptance
  Scenario: ONYX-9141: Identity is configured but empty, 500 Error
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
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/token-app-property"

  @negative @acceptance
  Scenario: ONYX-9143: Status webservice does not exist, 500 Error
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
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00005E Webservice 'authn-jwt/raw/status' not found"

  @negative @acceptance
  Scenario: ONYX-9569: JWKS-uri is configured but empty, 500 Error
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

  @negative @acceptance
  Scenario: ONYX-9570: Provider-uri is configured but empty, 500 Error
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

  @negative @acceptance
  Scenario: ONYX-9571: Provider-uri is configured with bad value, 500 Error
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

  @negative @acceptance
  Scenario: ONYX-9572: JWKS-uri is configured with bad value, 500 Error
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
    And the authenticator status check fails with error "CONJ00087E Failed to fetch JWKS from 'unknow-host.com'"

  @sanity
  @negative @acceptance
  Scenario: ONYX-9516: Identify-path is configured but empty, 500 Error
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
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/identity-path>"

  @sanity
  @smoke
  Scenario: ONYX-9515: Valid status check, identify-path is configured with value, 200 OK
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
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I successfully set authn-jwt "identity-path" variable to value "apps"
    And I successfully set authn-jwt "issuer" variable to value "gitlab"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds

  @acceptance
  Scenario: ONYX-10875: Status works fine with Enforced Claims and Aliases, 200 OK
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
        id: enforced-claims

      - !variable
        id: claim-aliases

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
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I successfully set authn-jwt "claim-aliases" variable to value "branch:ref"
    And I successfully set authn-jwt "enforced-claims" variable to value "ref"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds

  @negative @acceptance
  Scenario: ONYX-11162: Audience is configured but empty, 500 Error
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
        id: audience

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
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/audience>"

  @negative @acceptance
  Scenario: ONYX-10875: claim-aliases configured but secret not populated, 500 Error
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
        id: claim-aliases

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
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/claim-aliases>"

  @negative @acceptance
  Scenario: ONYX-10876: enforced-claims configured but secret not populated, 500 Error
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
        id: enforced-claims

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
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "CONJ00037E Missing value for resource: cucumber:variable:conjur/authn-jwt/raw/enforced-claims>"

  @negative @acceptance
  Scenario: ONYX-10960: enforced-claims configured with invalid value, 500 Error
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
        id: enforced-claims

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
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I successfully set authn-jwt "enforced-claims" variable to value "$@$@#sda//sdasdq23asd32rdf"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "does not match regular expression: '(?-mix:^[a-zA-Z|$|_][a-zA-Z|$|_|0-9|.]*(\/[a-zA-Z|$|_][a-zA-Z|$|_|0-9|.]*)*$)"

  @negative @acceptance
  Scenario Outline: ONYX-10958: claim-aliases configured with invalid value, 500 Error
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
        id: claim-aliases

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
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "user"
    And I successfully set authn-jwt "claim-aliases" variable to value "<claim-aliases-value>"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "<log>"
    Examples:
      | claim-aliases-value                              | log                                                                     |
      | SDsas213sda!!A!!$$@#$#:$@$@#sdasdasdq23asd32rdf  | does not match regular expression:                                      |
      | a/b:bbb                                          | Failed to parse claim aliases: the claim alias name 'a/b' contains '/'. |

  @negative @acceptance
  Scenario: ONYX-13997:  Identity is configured not according format, 500 Error
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

      - !variable
        id: audience

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
    And I successfully set authn-jwt "jwks-uri" variable value to "http://jwks_py:8090/authn-jwt-configuration/RS256" in service "raw"
    And I successfully set authn-jwt "token-app-property" variable to value "a//b"
    And I successfully set authn-jwt "issuer" variable to value "gitlab"
    And I successfully set authn-jwt "audience" variable to value "conjur"
    And I login as "alice"
    And I save my place in the log file
    When I GET "/authn-jwt/raw/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "Failed to parse 'token-app-property' value. Error:"
