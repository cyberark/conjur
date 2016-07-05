Feature: Rotating the API key

  Scenario: Authenticated users can rotate their own API key
    Given a new user
    Then I can rotate the API key
    And I can login

  Scenario: Bearer token cannot be used to rotate the API key
    Given a new user
    And I rotate the API key using a bearer token
    Then it's not authenticated

  Scenario: "Super" users can rotate user API keys
    Given a new user
    And I am a super-user
    Then I can rotate the API key using a bearer token
