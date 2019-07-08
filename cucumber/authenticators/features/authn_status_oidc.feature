Feature: OIDC Authenticator status check

  Scenario: A properly configured OIDC authenticator returns a successful response
    Given a policy:
    """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for Keycloak, based on Open ID Connect.

      - !webservice
        id: status
        annotations:
          description: Status service to verify the authenticator is configured correctly

      - !variable
        id: provider-uri

      - !variable
        id: id-token-user-property

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

      - !group
        id: managers
        annotations:
          description: Group of users who can check the status of the authn-oidc/keycloak authenticator

      - !permit
        role: !group managers
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/managers
      member: !user alice
    """
    And I am the super-user
    And I successfully set OIDC variables
    And I login as "alice"
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 200
    And the authenticator status check succeeds

  Scenario: A non-responsive OIDC provider returns a 500 response
    Given a policy:
    """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for Keycloak, based on Open ID Connect.

      - !webservice
        id: status
        annotations:
          description: Status service to verify the authenticator is configured correctly

      - !variable
        id: provider-uri

      - !variable
        id: id-token-user-property

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

      - !group
        id: managers
        annotations:
          description: Group of users who can check the status of the authn-oidc/keycloak authenticator

      - !permit
        role: !group managers
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/managers
      member: !user alice
    """
    And I am the super-user
    And I successfully set id-token-user-property variable
    And I successfully set provider-uri variable to value "https://not-responsive.com"
    And I login as "alice"
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "#<Errors::Authentication::AuthnOidc::ProviderDiscoveryFailed: CONJ00011E OIDC Provider discovery failed"

  Scenario: provider-uri variable is missing and a 500 error response is returned
    Given a policy:
     """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for Keycloak, based on Open ID Connect.

      - !webservice
        id: status
        annotations:
          description: Status service to verify the authenticator is configured correctly

      - !variable
        id: id-token-user-property

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

      - !group
        id: managers
        annotations:
          description: Group of users who can check the status of the authn-oidc/keycloak authenticator

      - !permit
        role: !group managers
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/managers
      member: !user alice
    """
    And I am the super-user
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "#<Errors::Conjur::RequiredResourceMissing: CONJ00036E Missing required resource: cucumber:variable:conjur/authn-oidc/keycloak/provider-uri>"

  Scenario: id-token-user-property variable is missing and a 500 error response is returned
    Given a policy:
     """
    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for Keycloak, based on Open ID Connect.

      - !webservice
        id: status
        annotations:
          description: Status service to verify the authenticator is configured correctly

      - !variable
        id: provider-uri

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

      - !group
        id: managers
        annotations:
          description: Group of users who can check the status of the authn-oidc/keycloak authenticator

      - !permit
        role: !group managers
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/managers
      member: !user alice
    """
    And I am the super-user
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "#<Errors::Conjur::RequiredResourceMissing: CONJ00036E Missing required resource: cucumber:variable:conjur/authn-oidc/keycloak/id-token-user-property>"

#  Scenario: provider-uri value has not been set and a 500 error response is returned
#  Scenario: id-token-user-property value has not been set and a 500 error response is returned

