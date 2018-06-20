Feature: Postgres password rotation

  Background: Configure a postgres rotator
    Given I reset my root policy
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
    And I watch for changes in "db-reports/password" and db user "test"
    And I create a db user "test" with password "secret"
    And I add the value "testdb" to variable "db-reports/url"
    And I add the value "test" to variable "db-reports/username"
    And I add the value "secret" to variable "db-reports/password"

  Scenario: Values are rotated
    Given I wait for 3 seconds
    And I stop watching for changes
    Then the first 3 db and conjur passwords match
