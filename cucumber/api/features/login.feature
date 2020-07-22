Feature: Exchange a role's password for its API key

  Roles which have passwords can use the `login` method to obtain their API key.
  The API key is then used to authenticate and receive an auth token.

  Background:
    Given I create a new user "alice"

  Scenario: Password can be used to obtain API key
    Given I set the password for "alice" to "My-Password1"
    When I can GET "/authn/cucumber/login" with username "alice" and password "My-Password1"
    Then the HTTP response content type is "text/plain"
    And the result is the API key for user "alice"

  @logged-in
  Scenario: Bearer token cannot be used to login

    The login method requires the password; login cannot be performed using the auth token
    as a credential.

    When I GET "/authn/cucumber/login"
    Then the HTTP response status code is 401

  @logged-in-admin
  Scenario: "Super" users cannot login as other users

    Users can never login as other users.

    When I GET "/authn/cucumber/login?role=user:alice"
    Then the HTTP response status code is 401
