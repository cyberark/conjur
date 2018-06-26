@logged-in
Feature: Manually expiring a rotating variable

  This feature is an API endpoint allowing a rotating variable to be expired
  prematurely.

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
               rotation/ttl: P1D
    """
    And I add the value "testdb" to variable "db-reports/url"
    And I add the value "test" to variable "db-reports/username"
    And I add the value "secret" to variable "db-reports/password"
    And I create a db user "test" with password "secret"

  Scenario: Expiring causes the secret to change

    Given I wait until "secret" is not longer the password
    And I successfully GET "/secrets/cucumber/variable/db-reports/password"
    And save the response as "initil-password"
    And I POST "/expirations/cucumber/variable/db-reports/password"
    Then the HTTP response status code is 201
    And the variable "db-reports/passwords" will rotate
