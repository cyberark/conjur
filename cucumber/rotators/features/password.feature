Feature: Postgres password rotation

  Background: Configure a postgres rotator
    Given I create a db user "test" with password "secret"
    And I have the root policy:
    """
    - !policy
       id: db-reports
       body:
         - &variables
           - !variable url
           - !variable username
           - !variable
             id: password
             annotations:
               rotation/rotator: postgresql/password
               rotation/ttl: PT1S
               rotation/postgresql/password/length: 32
    """
    And I add the value "testdb" to variable "db-reports/url"
    And I add the value "test" to variable "db-reports/username"
    And I add the value "secret" to variable "db-reports/password"

  Scenario: Initial values are correctly set
    Then the db password for "test" is "secret"
    And the "db-reports/password" variable is "secret"

  Scenario: Initial values are correctly set
    Given I wait for 1 second
    Then the "db-reports/password" variable is not "secret"
    # Then the db password for "test" is "secret"
