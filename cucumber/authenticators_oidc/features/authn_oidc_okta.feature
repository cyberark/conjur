@authenticators_oidc
Feature: OIDC Authenticator V2 - Users can authenticate with Okta using OIDC

  Background:
    Given I load a policy with okta user:
    """
      - !policy
        id: conjur/authn-oidc/okta-2
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
    And I am the super-user
    And I successfully set Okta OIDC V2 variables

  @smoke
  Scenario: Authenticating with Conjur using Okta
    Given I retrieve OIDC configuration from the provider endpoint for "okta-2"
    And I authenticate and fetch a code from Okta
    When I authenticate via OIDC with code and service_id "okta-2"
    Then the okta user has been authorized by conjur
