# alice and bob are in Conjur
# alice and charles are in LDAP
#
Feature: Authenticate a user

  Scenario: An LDAP user who doesn't exist in Conjur can authenticate
    When I authenticate as "charles"
    Then I get a token for "charles"

  Scenario: An LDAP user who exists in Conjur can authenticate
    When I authenticate as "alice"
    Then I get a token for "alice"

  Scenario: A user which is not in LDAP cannot authenticate
    When I authenticate as "bob"
    Then it is denied

  Scenario: An empty password may never be used to authenticate
    When I use the empty string as the password
    And I authenticate as "alice"
    Then it is denied

  Scenario: Invalid password prevents authentication
    When the password is incorrect
    And I authenticate as "alice"
    Then it is denied
