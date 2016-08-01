Feature: Exchanging base credentials for API key

  Background:
    Given a new user "alice"

  Scenario: Password can be used to obtain API key
    Given I set the password for "alice" to "my-password"
    Then I can GET "/authn/:account/login" with username "alice@:user_namespace" and password "my-password"
    Then the result is the API key for user "alice"

  @logged-in
  Scenario: Bearer token cannot be used to login
    When I GET "/authn/:account/login"
    Then it's not authenticated

  @logged-in-admin
  Scenario: "Super" users cannot login as other users
    When I GET "/authn/:account/login?role=user:alice@@user_namespace@"
    Then it's not authenticated
