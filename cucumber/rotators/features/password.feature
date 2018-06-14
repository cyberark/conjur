Feature: Postgres password rotation

  Background:
    Given I create a postgres user "test" with password "secret"

  Scenario: check
    Then I can login with user "test" and password "secret"
    And I cannot login with user "test" and password "WRONG PASSWORD"
