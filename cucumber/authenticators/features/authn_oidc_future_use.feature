Feature: Users can authneticate with OIDC authenticator

  Background:
    Given a policy:
    """
    - !user alice

    - !policy
      id: conjur/authn-oidc/keycloak
      body:
      - !webservice
        annotations:
          description: Authentication service for Keycloak, based on Open ID Connect.

      - !variable
        id: client-id

      - !variable
        id: client-secret

      - !variable
        id: provider-uri

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice
    """

    And I am the super-user
    And I successfully set OIDC variables


  Scenario: A valid authorization code and redirect uri to get Conjur access token
    Given I get authorization code
    When I successfully login via OIDC
    Then login response token is valid

    When I successfully authenticate via OIDC
    Then "alice" is authorized
