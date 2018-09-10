Feature: Users can login with LDAP credentials from an authorized LDAP server

  Background:
    Given a policy:
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

  Scenario: An LDAP user authorized in Conjur can login with a good password
    When I login via LDAP as authorized Conjur user "alice"
    And I authenticate via LDAP as authorized Conjur user "alice" using key
    Then "alice" is authorized

  Scenario: An LDAP user authorized in Conjur can authenticate with a good password
    When I authenticate via LDAP as authorized Conjur user "alice"
    Then "alice" is authorized

  Scenario: An LDAP user authorized in Conjur can't login with a bad password
    When my LDAP password is wrong for authorized user "alice"
    Then it is denied

  Scenario: 'admin' cannot use LDAP authentication
    When I login via LDAP as authorized Conjur user "admin"
    Then it is denied

  Scenario: An valid LDAP user who's not in Conjur can't login
    When I login via LDAP as non-existent Conjur user "bob"
    Then it is denied

  Scenario: An empty password may never be used to authenticate
    When my LDAP password for authorized Conjur user "alice" is empty
    Then it is denied

    #TODO Add an "is denied" for alice added to conjur but not entitled
  Scenario: An LDAP user in Conjur but without authorization can't login
    Given a policy:
    """
    - !user alice

    - !policy
      id: conjur/authn-ldap/test
      body:
      - !webservice

      - !group clients

      - !permit
        role: !group clients
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    When I login via LDAP as authorized Conjur user "alice"
    Then it is denied
