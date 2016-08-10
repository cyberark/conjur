Feature: Change the password of a role

  Each role can have a password. This is typically used for human users, not for machine roles.

  The password can be set or changed by providing either the current password or the API key as 
  the credential.

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

    An authentication token is insufficient to change a role's password.

    When I PUT "/authn/:account/password" with plain text body "new-password"
    Then it's not authenticated

  @logged-in-admin
  Scenario: "Super" users cannot update user passwords
    Users cannot change the passwords of other users. However, if a role has `update` privilege
    on another role, it can rotate the other role's API key.

    When I PUT "/authn/:account/password?role=user:alice@:user_namespace" with plain text body "new-password"
    Then it's not authenticated
