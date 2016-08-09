Feature: Obtaining an auth token

  Background:
    Given a new user "alice"

  Scenario: User can authenticate as herself
    Then I can POST "/authn/:account/alice@%3Auser_namespace/authenticate" with plain text body ":alice_api_key"

  Scenario: Invalid credentials result in 401 error
    When I POST "/authn/:account/alice@%3Auser_namespace/authenticate" with plain text body "wrong-api-key"
    Then it's not authenticated

  Scenario: User cannot login as a same-named user in a different account
    Given a new user "alice" in account "second-account"
    When I POST "/authn/second-account/alice@%3Auser_namespace/authenticate" with plain text body ":alice_api_key"
    Then it's not authenticated

  @logged-in
  Scenario: Auth tokens cannot be refreshed
    When I POST "/authn/:account/alice@%3Auser_namespace/authenticate"
    Then it's not authenticated

  @logged-in-admin
  Scenario: "Super" users cannot authenticate as other users
    When I POST "/authn/:account/alice@%3Auser_namespace/authenticate" with plain text body "wrong-api-key"
    Then it's not authenticated
