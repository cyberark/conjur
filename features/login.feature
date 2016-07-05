Feature: Exchanging base credentials for API key

  Scenario: Password can be used to obtain API key
    Given a user
    And a password
    Then I can login

  Scenario: Bearer token cannot be used to login
    Given a user
    And I login using a bearer token
    Then it's not authenticated

  Scenario: "Super" users cannot login
    Given a user
    And I am a super-user
    Then I login using a bearer token
    Then it's not authenticated
