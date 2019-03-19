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
    """
    And I am the super-user
    And I successfully set OIDC variables
    And I get authorization code
    And I fetch ID Token

  Scenario: A valid id token to get Conjur access token
    # We want to verify the returned access token is valid for retrieving a secret
    Given I have a "variable" resource called "test-variable"
    And I permit user "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    When I successfully authenticate via OIDC with id token
    Then "alice" is authorized
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user

  Scenario: A valid id token with email as id-token-user-property
    Given I have user "alice@conjur.net"
    # Add user `alice@conjur.net` to keycloak-users group
    And I successfully POST "/roles/cucumber/group/conjur%2Fauthn-oidc%2Fkeycloak%2Fusers?members&member=cucumber:user:alice@conjur.net"
    When I add the secret value "email" to the resource "cucumber:variable:conjur/authn-oidc/keycloak/id-token-user-property"
    And I successfully authenticate via OIDC with id token
    Then "alice@conjur.net" is authorized
