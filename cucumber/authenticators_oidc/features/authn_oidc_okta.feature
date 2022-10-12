# NOTE: This feature only tests the code exchange with Okta, it does not complete
# a full browser redirect request. This is adequate as this is the portion of the
# authentication process specific to Conjur.

@authenticators_oidc
Feature: OIDC Authenticator V2 - Users can authenticate with Okta using OIDC

  Background:
    Given I load a policy:
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
          - !variable redirect-uri

          - !group users

          - !permit
            role: !group users
            privilege: [ read, authenticate ]
            resource: !webservice
    """
    And I add an Okta user
    And I set conjur variables
      | variable_id                               | value                                                         | environment_variable  |
      | conjur/authn-oidc/okta-2/provider-uri     |                                                               | OKTA_PROVIDER_URI     |
      | conjur/authn-oidc/okta-2/client-id        |                                                               | OKTA_CLIENT_ID        |
      | conjur/authn-oidc/okta-2/client-secret    |                                                               | OKTA_CLIENT_SECRET    |
      | conjur/authn-oidc/okta-2/claim-mapping    | preferred_username                                            |                       |
      | conjur/authn-oidc/okta-2/redirect-uri     | http://localhost:3000/authn-oidc/okta/cucumber/authenticate |                       |

  @smoke
  Scenario: Authenticating with Conjur using Okta
    Given I fetch a code from Okta
    When I authenticate via OIDC V2 with code and service-id "okta-2"
    Then The Okta user has been authorized by Conjur
