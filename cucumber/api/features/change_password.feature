Feature: Updating the password

  Background:
    Given a new user "alice"

  Scenario: With basic authentication, users can update their own password
    When I successfully PUT "/authn/:account/password" with username "alice@:user_namespace" and password ":alice_password" and plain text body "new-password"
    Then I can POST "/authn/:account/alice@%3Auser_namespace/authenticate" with plain text body "new-password"

  @logged-in
  Scenario: Bearer token cannot be used to change the password
    When I PUT "/authn/:account/password" with plain text body "new-password"
    Then it's not authenticated

  @logged-in-admin
  Scenario: "Super" users cannot update user passwords
    When I PUT "/authn/:account/password?role=user:alice@:user_namespace" with plain text body "new-password"
    Then it's not authenticated
