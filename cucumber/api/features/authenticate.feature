Feature: Exchange a role's API key for a signed authentication token

  A role's API key can be used to obtain a signed authentication token.

  The token is a signed JSON structure that contains the role id. The 
  token can be sent as the `Authorization` header to other Conjur REST
  functions as proof of authentication.

  Background:
    Given I create a new user "alice"

  Scenario: A role's API can be used to authenticate
    Then I can POST "/authn/cucumber/alice/authenticate" with plain text body ":cucumber:user:alice_api_key"
    And there is an audit record matching:
    """
      <86>1 * * conjur * authn
      [auth@43868 authenticator="authn"]
      [subject@43868 role="cucumber:user:alice"]
      [action@43868 operation="authenticate" result="success"]
      cucumber:user:alice successfully authenticated with authenticator authn
    """

  Scenario: Attempting to use an invalid API key to authenticate result in 401 error
    When I POST "/authn/cucumber/alice/authenticate" with plain text body "wrong-api-key"
    Then the HTTP response status code is 401
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [auth@43868 authenticator="authn"]
      [subject@43868 role="cucumber:user:alice"]
      [action@43868 operation="authenticate" result="failure"]
      cucumber:user:alice failed to authenticate with authenticator authn
    """

  Scenario: User cannot login as a same-named user in a different account

    User logins are scoped per account. Conjur cannot be tricked into authenticating a user
    with a foreign account.

    Given I create a new user "alice" in account "second-account"
    When I POST "/authn/second-account/alice/authenticate" with plain text body ":cucumber:user:alice_api_key"
    Then the HTTP response status code is 401

  Scenario: Auth tokens cannot be refreshed

    The API key is required to authenticate. An authentication token is not a sufficient
    credential to re-authenticate. 

    Given I login as "alice"
    When I POST "/authn/cucumber/alice/authenticate"
    Then the HTTP response status code is 401

  @logged-in-admin
  Scenario: Roles cannot authenticate as any role other than themselves.

    A role cannot authenticate as another role, even a role that they can administer.

    When I POST "/authn/cucumber/alice/authenticate" with plain text body "wrong-api-key"
    Then the HTTP response status code is 401

  Scenario: A non existing user cannot authenticate
    Given I save my place in the log file
    When I POST "/authn/cucumber/non-existing/authenticate"
    Then the HTTP response status code is 401
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotFound
    """
