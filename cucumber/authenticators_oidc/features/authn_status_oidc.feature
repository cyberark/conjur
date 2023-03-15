@authenticators_oidc
Feature: OIDC Authenticator - Status Check

  Background:
    Given the following environment variables are available:
      | context_variable           | environment_variable   | default_value                                                   |
      | oidc_provider_uri          | PROVIDER_URI           | https://keycloak:8443/auth/realms/master                        |
      | oidc_claim_mapping         | ID_TOKEN_USER_PROPERTY | preferred_username                                              |

  @smoke
  Scenario: A properly configured OIDC authenticator returns a successful response
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
    And I set the following conjur variables:
      | variable_id                                       | context_variable   | default_value  |
      | conjur/authn-oidc/keycloak/provider-uri           | oidc_provider_uri  |                |
      | conjur/authn-oidc/keycloak/id-token-user-property | oidc_claim_mapping |                |

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
    And I set the following conjur variables:
      | variable_id                                       | context_variable    | default_value               |
      | conjur/authn-oidc/keycloak/provider-uri           |                     | https://not-responsive.com  |
      | conjur/authn-oidc/keycloak/id-token-user-property | oidc_claim_mapping  |                             |

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
    And I set the following conjur variables:
      | variable_id                                       | context_variable   | default_value |
      | conjur/authn-oidc/keycloak/id-token-user-property | oidc_claim_mapping |               |
    And I login as "alice"
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "RequiredResourceMissing: CONJ00036E"

  @negative @acceptance
  Scenario: id-token-user-property variable is missing and a 500 error response is returned
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
    And I set the following conjur variables:
      | variable_id                                       | context_variable   | default_value |
      | conjur/authn-oidc/keycloak/provider-uri           | oidc_provider_uri  |               |
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
    And I login as "alice"
    When I GET "/authn-oidc/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "Errors::Authentication::AuthnOidc::ServiceIdMissing"
