Feature: Updating the password

  @logged-in
  Scenario: Authenticated users can update their own password
    Then I can change the password
    And I can login

  @logged-in
  Scenario: Bearer token cannot be used to change the password
    When I change the password using a bearer token
    Then it's not authenticated

  @logged-in-admin
  Scenario: "Super" users cannot update user passwords
    Given a new user "alice"
    And I operate on "alice"
    When I change the password using a bearer token
    Then it's not authenticated
