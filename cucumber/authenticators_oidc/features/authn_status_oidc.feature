@authenticators_oidc
Feature: OIDC Authenticator - Status Check


  Background:
    Given I load a policy:
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

          - !variable name
          - !variable
            id: provider-uri

          - !variable
            id: response-type

          - !variable
            id: client-id

          - !variable
            id: client-secret

          - !variable
            id: claim-mapping

          - !variable
            id: state

          - !variable
            id: nonce

          - !variable
            id: redirect-uri

          - !variable
            id: provider-scope

          - !group users

          - !permit
            role: !group users
            privilege: [ read, authenticate ]
            resource: !webservice

          - !permit
            role: !group users
            privilege: [ read ]
            resource: !webservice status

      - !user
        id: alice
        annotations:
          authn-oidc/identity: alice.somebody@cyberark.com

      - !grant
        role: !group conjur/authn-oidc/keycloak/users
        member: !user alice
    """
    And I am the super-user
    And I successfully set OIDC V2 variables for "keycloak"

  @smoke
  Scenario: A properly configured OIDC authenticator returns a successful response
    And I login as "alice"
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds

  @negative @acceptance
  Scenario: A non-responsive OIDC provider returns a 500 response
    Given I load a policy:
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
        id: response-type

      - !variable
        id: client-id

      - !variable
        id: client-secret

      - !variable
        id: claim-mapping

      - !variable
        id: state

      - !variable
        id: nonce

      - !variable
        id: redirect-uri

      - !variable
        id: provider-scope

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
    And I successfully set OIDC V2 variables for "keycloak"
    And I successfully set provider-uri variable to value "https://not-responsive.com"
    And I login as "alice"
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "ProviderDiscoveryFailed: CONJ00011E"

  @negative @acceptance
  Scenario: provider-uri variable is missing and a 500 error response is returned
    Given I load a policy:
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
        id: response-type

      - !variable
        id: client-id

      - !variable
        id: client-secret

      - !variable
        id: claim-mapping

      - !variable
        id: state

      - !variable
        id: nonce

      - !variable
        id: redirect-uri

      - !variable
        id: provider-scope

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
    And I login as "alice"
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "RequiredResourceMissing: CONJ00036E"


  @negative @acceptance
  Scenario: service-id missing and a 500 error response is returned
    Given I load a policy:
    """
    - !policy
      id: conjur/authn-oidc
      body:
      - !webservice

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
          description: Group of users who can check the status of the authn-oidc authenticator

      - !permit
        role: !group managers
        privilege: [ read ]
        resource: !webservice status

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/users
      member: !user alice

    - !grant
      role: !group conjur/authn-oidc/managers
      member: !user alice
    """
    And I am the super-user
    And I login as "alice"
    When I GET "/authn-oidc/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "Errors::Authentication::AuthnOidc::ServiceIdMissing"

  # TODO: add these tests when issue #1085 is done
#  Scenario: provider-uri value has not been set and a 500 error response is returned
#  Scenario: id-token-user-property value has not been set and a 500 error response is returned

