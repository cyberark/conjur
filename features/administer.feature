Feature: Managing user records via foreign logins

  Background:
    Given a new user
    And a new user "charles"

  Scenario: API key cannot be rotated by foreign login without 'update' privilege
    Given I login as "charles"
    When I rotate the API key using a bearer token
    Then it's not authenticated

  Scenario: API key can be rotated by foreign login having 'update' privilege
    Given I give "update" privilege on the user to "charles"
    And I login as "charles"
    Then I can rotate the API key using a bearer token

