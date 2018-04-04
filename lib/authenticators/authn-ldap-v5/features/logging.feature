Feature: Capture logging output

  Scenario: Setting environment LOG_LEVEL=debug will print LDAP commands to stderr
    Given I enable logging
    And I authenticate as "alice"
