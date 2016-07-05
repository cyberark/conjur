Feature: Obtaining a bearer token

  Scenario: User can authenticate as herself
    Given a user
    Then I can authenticate

  Scenario: Invalid credentials result in 401 error
    Given a user
    And I use the wrong password
    When I authenticate
    Then it's not authenticated

  Scenario: "Super" users cannot authenticate as other users
    Given a user
    And I am a super-user
    And I use the wrong password
    When I authenticate
    Then it's not authenticated

  Scenario: New user can authenticate
    Given a new user
    Then I can authenticate
