@authenticators_ldap
Feature: Users can login with LDAP credentials from an authorized LDAP server

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

    - !policy
      id: conjur/authn-ldap/secure
      body:
      - !host
      - !webservice
        owner: !host
        annotations:
          ldap-authn/base_dn: dc=conjur,dc=net
          ldap-authn/bind_dn: cn=admin,dc=conjur,dc=net
          ldap-authn/connect_type: tls
          ldap-authn/host: ldap-server
          ldap-authn/port: 389
          ldap-authn/filter_template: (uid=%s)

      - !group clients

      - !permit
        role: !group clients
        privilege: [ read, authenticate ]
        resource: !webservice

      - !variable
        id: bind-password
        owner: !host

      - !variable
        id: tls-ca-cert
        owner: !host

    - !grant
      role: !group conjur/authn-ldap/secure/clients
      member: !user alice

    """
    And I store the LDAP bind password in "conjur/authn-ldap/secure/bind-password"
    And I store the LDAP CA certificate in "conjur/authn-ldap/secure/tls-ca-cert"

  @smoke
  Scenario: An LDAP user authorized in Conjur can login with a good password
    Given I save my place in the log file
    When I login via LDAP as authorized Conjur user "alice"
    And I authenticate via LDAP as authorized Conjur user "alice" using key
    Then user "alice" has been authorized by Conjur
    And The following appears in the log after my savepoint:
    """
    cucumber:user:alice successfully authenticated with authenticator authn-ldap service cucumber:webservice:conjur/authn-ldap/test
    """

  @smoke
  Scenario: An LDAP user authorized in Conjur can login with a good password using TLS
    When I login via secure LDAP as authorized Conjur user "alice"
    And I authenticate via secure LDAP as authorized Conjur user "alice" using key
    Then user "alice" has been authorized by Conjur

  @smoke
  Scenario: An LDAP user authorized in Conjur can authenticate with a good password
    When I authenticate via LDAP as authorized Conjur user "alice"
    Then user "alice" has been authorized by Conjur

  @negative @acceptance
  Scenario: An LDAP user authorized in Conjur can't login with a bad password
    When my LDAP password is wrong for authorized user "alice"
    Then it is unauthorized

  @negative @acceptance
  Scenario: 'admin' cannot use LDAP authentication
    When I login via LDAP as authorized Conjur user "admin"
    Then it is unauthorized

  @negative @acceptance
  Scenario: An valid LDAP user who's not in Conjur can't login
    When I login via LDAP as non-existent Conjur user "bob"
    Then it is forbidden

  @negative @acceptance
  Scenario: An empty password may never be used to authenticate
    When my LDAP password for authorized Conjur user "alice" is empty
    Then it is unauthorized

  #TODO Add an "is denied" for alice added to conjur but not entitled
  @negative @acceptance
  Scenario: An LDAP user in Conjur but without authorization can't login
    Given I load a policy:
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
    Then it is forbidden

  # This test runs a failing authentication request that is already tested in
  # another scenario (An LDAP user authorized in Conjur can't login with a bad
  # password). We run it again here to verify that we write a message to the
  # audit log in Syslog format.  This is our e2e test that the Syslog formatter
  # is working correctly.
  @smoke
  Scenario: Authentication failure is logged in Syslog format
    Given I save my place in the audit log file
    When my LDAP password is wrong for authorized user "alice"
    Then it is unauthorized
    And The following matches the audit log after my savepoint:
    """
    <84>1 \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z - conjur \d+ authn \[subject@43868 role="cucumber:user:alice"]\[auth@43868 user="cucumber:user:alice" authenticator="authn-ldap" service="cucumber:webservice:conjur/authn-ldap/test"]\[client@43868 ip="\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"]\[action@43868 result="failure" operation="login"] cucumber:user:alice failed to login with authenticator authn-ldap service cucumber:webservice:conjur/authn-ldap/test: CONJ00002E Invalid credentials
    """
