Feature: The list of available authentication providers is discoverable
  through the API.

  Background:
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

  Scenario: List authenticators
  
  When I retrieve the list of authenticators
  Then the installed authenticators contains "authn-ldap"
  And the configured authenticators contains "authn-ldap/test"
  And the enabled authenticators contains "authn-ldap/test"