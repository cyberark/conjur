@rotators
Feature: Rotate slosilo key. When rotation occurs twice in a row,
  the user is logged out (token is not valid anymore) and should log in again.
  Scenario: Slosilo is rotated twice
    Given I load a policy:
    """
    - !user alice
    - !variable
      id: db-password
      owner: !user alice
    """
    And I log in as user "alice"
    Then I can add a secret to variable resource "db-password"
    When Slosilo key is rotated
    Then I can add a secret to variable resource "db-password"
    When Slosilo key is rotated
    And I add a secret to variable resource "db-password"
    Then The response status code is 401
    Given I log in as user "alice"
    Then I can add a secret to variable resource "db-password"
