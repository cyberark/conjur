@rotators
Feature: Rotate Slosilo key. When rotation occurs twice in a row,
  the user is logged out (token is not valid anymore) and should log in again.
  Scenario: Logged in as user, Slosilo is rotated twice
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

  Scenario: Logged in as host, Slosilo is rotated twice
    Given I load a policy:
    """
    - !host
       id: myapp
       annotations:
         authn/api-key: true
    - !variable
      id: app-password
      owner: !host myapp
    """
    And I log in as host "myapp"
    Then I can add a secret to variable resource "app-password"
    When Slosilo key is rotated
    Then I can add a secret to variable resource "app-password"
    When Slosilo key is rotated
    And I add a secret to variable resource "app-password"
    Then The response status code is 401
    Given I log in as host "myapp"
    Then I can add a secret to variable resource "app-password"
