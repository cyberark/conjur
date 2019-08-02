Feature: Users can authenticate with OIDC & LDAP authenticators

  Background:
    # Configure OIDC authenticator
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
    # Configure LDAP authenticator
    And I extend the policy with:
    """
    - !policy
      id: conjur/authn-ldap/test
      body:
      - !webservice

      - !group clients

      - !permit
        role: !group clients
        privilege: [ read, authenticate ]
        resource: !webservice

    - !grant
      role: !group conjur/authn-ldap/test/clients
      member: !user alice
    """

  Scenario: Users can authenticate with 2 authenticators
    # We want to verify the returned access token is valid for retrieving a secret
    Given I have a "variable" resource called "test-variable"
    And I permit user "alice" to "execute" it
    And I add the secret value "test-secret" to the resource "cucumber:variable:test-variable"
    # Authenticate with authn-oidc
    And I fetch an ID Token for username "alice" and password "alice"
    When I authenticate via OIDC with id token
    Then user "alice" is authorized
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
    # Authenticate with authn-ldap
    When I login via LDAP as authorized Conjur user "alice"
    And I authenticate via LDAP as authorized Conjur user "alice" using key
    Then user "alice" is authorized
    And I successfully GET "/secrets/cucumber/variable/test-variable" with authorized user
