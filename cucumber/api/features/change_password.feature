Feature: Updating the password

  Background:
    Given a new user "alice"

  Scenario: With basic authentication, users can update their own password using the current password.
    Given I set the password for "alice" to "my-password"
    When I successfully PUT "/authn/:account/password" with username "alice@:user_namespace" and password "my-password" and plain text body "new-password"
    Then I can GET "/authn/:account/login" with username "alice@:user_namespace" and password "new-password"

  Scenario: With basic authentication, users can update their own password using the current API key.
    When I successfully PUT "/authn/:account/password" with username "alice@:user_namespace" and password ":alice_api_key" and plain text body "new-password"
    Then I can GET "/authn/:account/login" with username "alice@:user_namespace" and password "new-password"

  @logged-in
  Scenario: Bearer token cannot be used to change the password
    When I PUT "/authn/:account/password" with plain text body "new-password"
    Then it's not authenticated

  @logged-in-admin
  Scenario: "Super" users cannot update user passwords
    When I PUT "/authn/:account/password?role=user:alice@:user_namespace" with plain text body "new-password"
    Then it's not authenticated
