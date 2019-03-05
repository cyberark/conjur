Feature: Users can authneticate with OIDC authenticator

  Background:
    Given a policy:
    """
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

      - !variable
        id: id-token-user-property

      - !group users

      - !permit
        role: !group users
        privilege: [ read, authenticate ]
        resource: !webservice

    - !user alice

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice

    - !user alice@conjur.net

    - !grant
      role: !group conjur/authn-oidc/keycloak/users
      member: !user alice@conjur.net
    """
    And I am the super-user
    And I successfully set OIDC variables

  Scenario: A valid id token to get Conjur access token
    When I successfully authenticate via OIDC
    Then "alice" is authorized

  Scenario: A valid id token with email as id-token-user-property
    When I add the secret value "email" to the resource "cucumber:variable:conjur/authn-oidc/keycloak/id-token-user-property"
    And I successfully authenticate via OIDC
    Then "alice@conjur.net" is authorized
