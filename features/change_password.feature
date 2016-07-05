Feature: Updating the password

  Scenario: Authenticated users can update their own password
    Given a new user
    Then I can change the password
    And I can login

  Scenario: Bearer token cannot be used to change the password
    Given a new user
    And I change the password using a bearer token
    Then it's not authenticated

  Scenario: "Super" users cannot update user passwords
    Given a new user
    And I am a super-user
    And I change the password using a bearer token
    Then it's not authenticated
