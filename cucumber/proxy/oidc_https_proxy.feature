@proxy
Feature: OIDC Status Check With Proxy

  Background:
    Given the following environment variables are available:
      | context_variable           | environment_variable   | default_value                                                   |
      | oidc_provider_uri          | PROVIDER_URI           | https://keycloak:8443/auth/realms/master                        |
      | oidc_claim_mapping         | ID_TOKEN_USER_PROPERTY | preferred_username                                              |
      | oidc_ca_cert               | KEYCLOAK_CA_CERT       |                                                                 |
    And I load a policy:
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
      
      - !variable
        id: ca-cert

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
      | conjur/authn-oidc/keycloak/ca-cert | oidc_ca_cert |                    |
    And I login as "alice"

  @smoke
  Scenario: A properly configured OIDC authenticator and proxy returns a successful response
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And the authenticator status check succeeds

  @negative @acceptance
  Scenario: A non-responsive proxy returns a 500 response
    When I GET "/authn-oidc/keycloak/cucumber/status"
    Then the HTTP response status code is 500
    And the authenticator status check fails with error "ProviderDiscoveryFailed: CONJ00011E"
