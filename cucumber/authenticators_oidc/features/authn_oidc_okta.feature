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
          - !variable state
          - !variable nonce
          - !variable redirect-uri
          - !group users

          - !permit
            role: !group users
            privilege: [ read, authenticate ]
            resource: !webservice

      - !user
        id: ellis.wright
        annotations:
          authn-oidc/identity: ellis.wright@cyberark.com

      - !grant
        role: !group conjur/authn-oidc/okta-2/users
        member: !user ellis.wright
    """
    And I am the super-user
    And I successfully set Okta OIDC V2 variables

  @smoke
  Scenario: Authenticating with Conjur using Okta
    Given I fetch a code from okta for username "ellis.wright@cyberark.com" and password "M59v3TIhUOn2"
    When I authenticate via OIDC with code and service_id "okta-2"
    Then user "ellis.wright" has been authorized by Conjur
