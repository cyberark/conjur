@authenticators_oidc
Feature: OIDC Authenticator V2 - Users can authenticate with Identity using OIDC

  Background:
    Given the following environment variables are available:
      | context_variable   | environment_variable   | default_value                                                   |
      | oidc_provider_uri  | IDENTITY_PROVIDER_URI  |                                                                 |
      | oidc_client_id     | IDENTITY_CLIENT_ID     |                                                                 |
      | oidc_client_secret | IDENTITY_CLIENT_SECRET |                                                                 |
      | oidc_redirect_url  | IDENTITY_REDIRECT      | http://localhost:3000/authn-oidc/identity/cucumber/authenticate |
      | oidc_username      | IDENTITY_USERNAME      |                                                                 |
      | oidc_password      | IDENTITY_PASSWORD      |                                                                 |

    And I load a policy and enable an oidc user into group "conjur/authn-oidc/identity/users":
    """
      - !policy
        id: conjur/authn-oidc/identity
        body:
          - !webservice
            annotations:
              description: Authentication service for Identity, based on Open ID Connect.

          - !variable provider-uri
          - !variable client-id
          - !variable client-secret
          - !variable claim-mapping
          - !variable state
          - !variable nonce
          - !variable redirect-uri

          - !group users

          - !permit
            role: !group users
            privilege: [ read, authenticate ]
            resource: !webservice
    """
    And I set the following conjur variables:
      | variable_id                               | context_variable    | default_value       |
      | conjur/authn-oidc/identity/provider-uri   | oidc_provider_uri   |                     |
      | conjur/authn-oidc/identity/client-id      | oidc_client_id      |                     |
      | conjur/authn-oidc/identity/client-secret  | oidc_client_secret  |                     |
      | conjur/authn-oidc/identity/claim-mapping  |                     | email               |
      | conjur/authn-oidc/identity/redirect-uri   | oidc_redirect_url   |                     |

  @smoke
  Scenario: Authenticating with Conjur using Identity
    Given I retrieve OIDC configuration from the provider endpoint for "identity"
    And I authenticate and fetch a code from Identity
    When I authenticate via OIDC with code and service_id "identity"
    Then the OIDC user has been authorized by conjur
