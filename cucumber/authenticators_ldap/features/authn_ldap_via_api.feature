@authenticators_ldap
Feature: LDAP Authenticator created via API

  Background:
    Given I load a policy:
    """
    - !policy conjur/authn-ldap
    """
    And I successfully initialize an LDAP authenticator named "api-ldap" via the authenticators API
    And I successfully initialize an LDAP authenticator named "api-ldap-variables" using variables via the authenticators API
    And I extend the policy with:
    """
    - !user alice

    - !grant
      role: !group conjur/authn-ldap/api-ldap/apps
      member: !user alice

    - !grant
      role: !group conjur/authn-ldap/api-ldap-variables/apps
      member: !user alice
    """

  @smoke
  Scenario: An LDAP user authorized in Conjur can login with a good password
    Given I save my place in the log file
    When I login via api-ldap LDAP as authorized Conjur user "alice"
    And I authenticate via api-ldap LDAP as authorized Conjur user "alice" using key
    Then user "alice" has been authorized by Conjur
    And The following appears in the log after my savepoint:
    """
    cucumber:user:alice successfully authenticated with authenticator authn-ldap service cucumber:webservice:conjur/authn-ldap/api-ldap
    """

  @smoke
  Scenario: An LDAP user authorized in Conjur can authenticate with a good password
    When I authenticate via api-ldap LDAP as authorized Conjur user "alice"
    Then user "alice" has been authorized by Conjur

  @smoke
  Scenario: An LDAP user authorized in Conjur can login with a good password using TLS
    When I login via api-ldap-variables LDAP as authorized Conjur user "alice"
    And I authenticate via api-ldap-variables LDAP as authorized Conjur user "alice" using key
    Then user "alice" has been authorized by Conjur
