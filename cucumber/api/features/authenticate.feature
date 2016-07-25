Feature: Obtaining a bearer token

  @logged-in
  Scenario: User can authenticate as herself
    Then I can authenticate

  @logged-in
  Scenario: Invalid credentials result in 401 error
    And I use the wrong password
    When I authenticate
    Then it's not authenticated

  @logged-in-admin
  Scenario: "Super" users cannot authenticate as other users
    Given a new user "alice"
    And I operate on "alice"
    And I use the wrong password
    When I authenticate
    Then it's not authenticated
