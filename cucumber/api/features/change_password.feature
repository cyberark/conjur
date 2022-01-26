@api
Feature: Change the password of a role

  Each role can have a password. This is typically used for human users, not for machine roles.

  The password can be set or changed by providing either the current password or the API key as
  the credential.

  Background:
    Given I create a new user "alice"

  @smoke
  Scenario: With basic authentication, users can update their own password using the current password.

    Given I set the password for "alice" to "My-Password1"
    And I save my place in the audit log file for remote
    When I successfully PUT "/authn/cucumber/password" with username "alice" and password "My-Password1" and plain text body "New-Password1"
    Then I can GET "/authn/cucumber/login" with username "alice" and password "New-Password1"
    And there is an audit record matching:
    """
      <86>1 * * conjur * password
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 role="cucumber:user:alice"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="change"]
      cucumber:user:alice successfully changed their password
    """

  @smoke
  Scenario: With basic authentication, user admin update their own password using the current password.

    Given I set the password for "admin" to "My-Password1"
    And I save my place in the audit log file for remote
    When I successfully PUT "/authn/cucumber/password" with username "admin" and password "My-Password1" and plain text body "New-Password1"
    Then I can GET "/authn/cucumber/login" with username "admin" and password "New-Password1"
    And there is an audit record matching:
    """
      <86>1 * * conjur * password
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:user:admin"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="change"]
      cucumber:user:admin successfully changed their password
    """

  @smoke
  Scenario: With basic authentication, users can update their own password using the current API key.

    When I successfully PUT "/authn/cucumber/password" with username "alice" and password ":cucumber:user:alice_api_key" and plain text body "New-Password1"
    Then I can GET "/authn/cucumber/login" with username "alice" and password "New-Password1"

  @acceptance
  Scenario: Succeed to set password with escaped special character applying to password complexity.

    Given I set the password for "alice" to "My-Password1"
    When I successfully PUT "/authn/cucumber/password" with username "alice" and password "My-Password1" and plain text body "NewPassword1/"
    Then I can GET "/authn/cucumber/login" with username "alice" and password "NewPassword1/"

  @negative @acceptance
  Scenario: Fail to set password with 11 characters not applying to password complexity.

    Given I set the password for "alice" to "My-Password1"
    And I save my place in the audit log file for remote
    When I PUT "/authn/cucumber/password" with username "alice" and password "My-Password1" and plain text body "My-Passwor1"
    Then the HTTP response status code is 422
    And there is an audit record matching:
    """
      <84>1 * * conjur * password
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 role="cucumber:user:alice"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="change"]
      cucumber:user:alice failed to change their password:
      password CONJ00046E *
    """

  @negative @acceptance
  Scenario: Bearer token cannot be used to change the password

    An authentication token is insufficient to change a role's password.

    Given I login as "alice"
    When I PUT "/authn/cucumber/password" with plain text body "new-password"
    Then the HTTP response status code is 401

  @negative @acceptance
  @logged-in-admin
  Scenario: "Super" users cannot update user passwords
    Users cannot change the passwords of other users. However, if a role has `update` privilege
    on another role, it can rotate the other role's API key.

    When I PUT "/authn/cucumber/password?role=user:alice" with plain text body "new-password"
    Then the HTTP response status code is 401
