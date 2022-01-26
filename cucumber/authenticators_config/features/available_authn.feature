@authenticators_config
Feature: The list of available authentication providers is discoverable
  through the API.

  @sanity
  @smoke
  Scenario: ONYX-12104 - Verify installed authenticators
    When I retrieve the list of authenticators
    Then there are exactly 8 installed authenticators
    And the installed authenticators contains "authn"
    And the installed authenticators contains "authn-azure"
    And the installed authenticators contains "authn-gcp"
    And the installed authenticators contains "authn-iam"
    And the installed authenticators contains "authn-jwt"
    And the installed authenticators contains "authn-k8s"
    And the installed authenticators contains "authn-ldap"
    And the installed authenticators contains "authn-oidc"

  @smoke
  Scenario: List authenticators
    Given I load a policy:
    """
    - !user alice
    - !user bob

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
    When I retrieve the list of authenticators
    Then the installed authenticators contains "authn-ldap"
    And the configured authenticators contains "authn-ldap/test"
    And the enabled authenticators contains "authn-ldap/test"
