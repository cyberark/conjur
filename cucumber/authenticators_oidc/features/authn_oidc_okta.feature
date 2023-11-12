@authenticators_oidc
Feature: OIDC Authenticator V2 - Users can authenticate with Okta using OIDC

  Background:
    Given the following environment variables are available:
      | context_variable   | environment_variable | default_value                                               |
      | oidc_provider_uri  | OKTA_PROVIDER_URI    |                                                             |
      | oidc_client_id     | OKTA_CLIENT_ID       |                                                             |
      | oidc_client_secret | OKTA_CLIENT_SECRET   |                                                             |
      | oidc_redirect_url  | OKTA_REDIRECT        | http://localhost:3000/authn-oidc/okta/cucumber/authenticate |
      | oidc_username      | OKTA_USERNAME        |                                                             |
      | oidc_password      | OKTA_PASSWORD        |                                                             |

    And I load a policy and enable an oidc user into group "conjur/authn-oidc/okta/users":
    """
      - !policy
        id: conjur/authn-oidc/okta
        body:
          - !webservice
            annotations:
              description: Authentication service for Okta, based on Open ID Connect.

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
      | variable_id                           | context_variable    | default_value       |
      | conjur/authn-oidc/okta/provider-uri   | oidc_provider_uri   |                     |
      | conjur/authn-oidc/okta/client-id      | oidc_client_id      |                     |
      | conjur/authn-oidc/okta/client-secret  | oidc_client_secret  |                     |
      | conjur/authn-oidc/okta/claim-mapping  |                     | preferred_username  |
      | conjur/authn-oidc/okta/redirect-uri   | oidc_redirect_url   |                     |

  @smoke @skip
  Scenario: Authenticating with Conjur using Okta
    Given I retrieve OIDC configuration from the provider endpoint for "okta"
    And I authenticate and fetch a code from Okta
    When I authenticate via OIDC with code and service_id "okta"
    Then the okta user has been authorized by conjur
