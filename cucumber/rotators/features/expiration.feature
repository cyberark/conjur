@rotators
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
               rotation/postgresql/password/length: 32
    """
    And I add the value "testdb" to variable "db-reports/url"
    And I add the value "test" to variable "db-reports/username"
    And I add the value "secret" to variable "db-reports/password"
    And I create a db user "test" with password "secret"

  @smoke
  Scenario: Expiring causes the secret to change

    # The initial password is rotated right away, and the subsequent rotation
    # won't occur for a full day.  We wait for the initial rotation to occur
    # before proceeding, because the 2nd password (ie, the first one generated
    # by the rotator) will be stable, so we'll know if our early expiration
    # works.
    #
    Given I wait until the initial password has rotated away
    And I login as "admin"
    And I successfully GET "/secrets/cucumber/variable/db-reports/password"
    And I save the response as "password_before_expiration"
    And I POST "/secrets/cucumber/variable/db-reports/password?expirations"
    Then the HTTP response status code is 201
    And the HTTP response content type is "text/html"
    And the password will change from "password_before_expiration"
