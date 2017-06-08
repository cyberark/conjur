Feature: Rotate the API key of a role

  The API key of a role can be automatically changed ("rotated") to a new random string.

  A role can rotate its own API key using the password or current API key. A role can also
  rotate the API key of another role if it has `update` privilege on the role.

  Background:
    Given I create a new user "alice"

  Scenario: Password can be used to rotate API key
    Given I set the password for "alice" to "my-password"
    Then I can PUT "/authn/cucumber/api_key" with username "alice" and password "my-password"
    Then the result is the API key for user "alice"

  @logged-in
  Scenario: The API key cannot be rotated by foreign role without 'update' privilege
    Given I create a new user "bob"
    When I PUT "/authn/cucumber/api_key?role=user:bob"
    Then the HTTP response status code is 401

  @logged-in
  Scenario: The API key can be rotated by foreign role when it has 'update' privilege
    Given I create a new user "bob"
    And I permit user "alice" to "update" user "bob"
    When I PUT "/authn/cucumber/api_key?role=user:bob"
    Then the result is the API key for user "bob"
