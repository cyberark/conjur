Feature: Exchange a role's API key for a signed authentication token

  A role's API key can be used to obtain a signed authentication token.

  The token is a signed JSON structure that contains the role id. The 
  token can be sent as the `Authorization` header to other Possum REST
  functions as proof of authentication.

  Background:
    Given I create a new user "alice"

  Scenario: A role's API can be used to authenticate
    Then I can POST "/authn/cucumber/alice/authenticate" with plain text body ":alice_api_key"

  Scenario: Attempting to use an invalid API key to authenticate result in 401 error
    When I POST "/authn/cucumber/alice/authenticate" with plain text body "wrong-api-key"
    Then it's not authenticated

  Scenario: User cannot login as a same-named user in a different account

    User logins are scoped per account. Possum cannot be tricked into authenticating a user
    with a foreign account.

    Given I create a new user "alice" in account "second-account"
    When I POST "/authn/second-account/alice/authenticate" with plain text body ":alice_api_key"
    Then it's not authenticated

  @logged-in
  Scenario: Auth tokens cannot be refreshed

    The API key is required to authenticate. An authentication token is not a sufficient
    credential to re-authenticate. 

    When I POST "/authn/cucumber/alice/authenticate"
    Then it's not authenticated

  @logged-in-admin
  Scenario: Roles cannot authenticate as any role other than themselves.

    A role cannot authenticate as another role, even a role that they can administer.

    When I POST "/authn/cucumber/alice/authenticate" with plain text body "wrong-api-key"
    Then it's not authenticated
