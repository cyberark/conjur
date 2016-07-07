Feature: Rotating API keys

  @logged-in
  Scenario: Password can be used to obtain API key
    Given I have a password
    Then I can rotate the API key

  @logged-in
  Scenario: API key cannot be rotated by foreign login without 'update' privilege
    Given a new user "bob"
    And I operate on "bob"
    When I rotate the API key using a bearer token
    Then it's not authenticated

  @logged-in
  Scenario: API key can be rotated by foreign login having 'update' privilege
    Given a new user "bob"
    And a new user "charles"
    And I permit user "bob" to "update" user "charles"
    And I login as "bob"
    And I operate on "charles"
    Then I can rotate the API key using a bearer token
