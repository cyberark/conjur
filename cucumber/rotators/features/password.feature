@rotators
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
    And I add the value "testdb" to variable "db-reports/url"
    And I add the value "test" to variable "db-reports/username"
    And I add the value "secret" to variable "db-reports/password"
    And I create a db user "test" with password "secret"

  # NOTE: To make these tests robust on unreliable Jenkins servers that may
  #       not be able to respect `sleep` times exactly, we give ourselves 
  #       some leeway, waiting for 3 rotations but allowing for more than
  #       3 seconds of time.
  #
  @smoke
  Scenario: Values are rotated according to the policy
    Given I moniter "db-reports/password" and db user "test" for 3 values in 20 seconds
    Then we find at least 3 distinct matching passwords
    And the generated passwords have length 32
