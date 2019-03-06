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
    """
    And I am the super-user
    And I successfully set OIDC variables

  Scenario: A valid id token to get Conjur access token
    When I successfully authenticate via OIDC with id token:
    """
    {"preferred_username": "alice","email": "alice@conjur.net"}
    """

    Then "alice" is authorized

    # Verify the returned access token is valid for retrieving a secret
    Given a policy:
    """
    - !variable test-variable
    - !user alice

    - !permit
      role: !user alice
      privilege: [ read, execute ]
      resource: !variable test-variable
    """
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"

    Then I successfully GET "/secrets/cucumber/variable/test-variable" with user "alice"

  Scenario: A valid id token with email as id-token-user-property
    # Add user `alice@conjur.net` to keycloak-users group
    Given I successfully POST "/roles/cucumber/group/conjur%2Fauthn-oidc%2Fkeycloak%2Fusers?members&member=cucumber:user:alice@conjur.net"

    When I add the secret value "email" to the resource "cucumber:variable:conjur/authn-oidc/keycloak/id-token-user-property"
    And I successfully authenticate via OIDC with id token:
    """
    {"preferred_username": "alice","email": "alice@conjur.net"}
    """
    Then "alice@conjur.net" is authorized
