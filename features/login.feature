Feature: Exchanging base credentials for API key

  @logged-in
  Scenario: Password can be used to obtain API key
    Given I have a password
    Then I can login

  @logged-in
  Scenario: Bearer token cannot be used to login
    When I login using a bearer token
    Then it's not authenticated

  @logged-in-admin
  Scenario: "Super" users cannot login as other users
    Given a new user "alice"
    And I operate on "alice"
    When I login using a bearer token
    Then it's not authenticated
