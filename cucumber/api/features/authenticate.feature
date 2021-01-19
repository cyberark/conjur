Feature: Exchange a role's API key for a signed authentication token

  A role's API key can be used to obtain a signed authentication token.

  The token is a signed JSON structure that contains the role id. The 
  token can be sent as the `Authorization` header to other Conjur REST
  functions as proof of authentication.
  Background:
    Given I create a new user "alice"
    And I have host "app"

  Scenario: A role's API can be used to authenticate
    Then I can POST "/authn/cucumber/alice/authenticate" with plain text body ":cucumber:user:alice_api_key"
    And the HTTP response content type is "application/json"
    And there is an audit record matching:
    """
      <86>1 * * conjur * authn
      [auth@43868 authenticator="authn" user="cucumber:user:alice"]
      [subject@43868 role="cucumber:user:alice"]
      [action@43868 operation="authenticate" result="success"]
      cucumber:user:alice successfully authenticated with authenticator authn
    """

  Scenario: A host's API can be used to authenticate
    Then I can POST "/authn/cucumber/host%2Fapp/authenticate" with plain text body ":cucumber:host:app_api_key"
    And the HTTP response content type is "application/json"
    And there is an audit record matching:
    """
      <86>1 * * conjur * authn
      [auth@43868 authenticator="authn" user="cucumber:host:app"]
      [subject@43868 role="cucumber:host:app"]
      [action@43868 operation="authenticate" result="success"]
      cucumber:host:app successfully authenticated with authenticator authn
    """

  Scenario: X-Request-Id is set and visible in the audit record
    Given I set the "X-Request-Id" header to "TestMyApp"
    Then I can POST "/authn/cucumber/alice/authenticate" with plain text body ":cucumber:user:alice_api_key"
    And the HTTP response content type is "application/json"
    And there is an audit record matching:
    """
      <86>1 * * conjur TestMyApp authn
      [auth@43868 authenticator="authn"]
      [subject@43868 role="cucumber:user:alice"]
      [action@43868 operation="authenticate" result="success"]
      cucumber:user:alice successfully authenticated with authenticator authn
    """

  Scenario: Authenticate response should be encoded if Accept-Encoding equals base64
    When I successfully authenticate Alice with Accept-Encoding header "base64"
    Then the HTTP response content type is "text/plain"
    And the HTTP response is base64 encoded
    And user "alice" has been authorized by Conjur
    And there is an audit record matching:
    """
      <86>1 * * conjur * authn
      [auth@43868 authenticator="authn" user="cucumber:user:alice"]
      [subject@43868 role="cucumber:user:alice"]
      [action@43868 operation="authenticate" result="success"]
      cucumber:user:alice successfully authenticated with authenticator authn
    """

  Scenario: Authenticate response should be encoded if Accept-Encoding includes base64
    When I successfully authenticate Alice with Accept-Encoding header "base64,gzip,defalte,br"
    Then the HTTP response content type is "text/plain"
    And the HTTP response is base64 encoded
    And user "alice" has been authorized by Conjur
    And there is an audit record matching:
    """
      <86>1 * * conjur * authn
      [auth@43868 authenticator="authn" user="cucumber:user:alice"]
      [subject@43868 role="cucumber:user:alice"]
      [action@43868 operation="authenticate" result="success"]
      cucumber:user:alice successfully authenticated with authenticator authn
    """

  Scenario: Authenticate response should be encoded if Accept-Encoding includes base64 with mixed case and spaces
    When I successfully authenticate Alice with Accept-Encoding header "gzip      ,  bASe64 ,defalte,br"
    Then the HTTP response content type is "text/plain"
    And the HTTP response is base64 encoded
    And user "alice" has been authorized by Conjur
    And there is an audit record matching:
    """
      <86>1 * * conjur * authn
      [auth@43868 authenticator="authn" user="cucumber:user:alice"]
      [subject@43868 role="cucumber:user:alice"]
      [action@43868 operation="authenticate" result="success"]
      cucumber:user:alice successfully authenticated with authenticator authn
    """

  Scenario: Authenticate response should be json if Accept-Encoding doesn't include base64
    When I successfully authenticate Alice with Accept-Encoding header "gzip,defalte,br"
    Then the HTTP response content type is "application/json"
    And there is an audit record matching:
    """
      <86>1 * * conjur * authn
      [auth@43868 authenticator="authn" user="cucumber:user:alice"]
      [subject@43868 role="cucumber:user:alice"]
      [action@43868 operation="authenticate" result="success"]
      cucumber:user:alice successfully authenticated with authenticator authn
    """

  Scenario: Authenticating with no Content-Type header succeeds without writing API key to the logs
    And I save my place in the log file
    And I can authenticate Alice with no Content-Type header
    Then Alice's API key does not appear in the log

  Scenario: Attempting to use an invalid API key to authenticate result in 401 error
    When I POST "/authn/cucumber/alice/authenticate" with plain text body "wrong-api-key"
    Then the HTTP response status code is 401
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [auth@43868 authenticator="authn" user="cucumber:user:alice"]
      [subject@43868 role="cucumber:user:alice"]
      [action@43868 operation="authenticate" result="failure"]
      cucumber:user:alice failed to authenticate with authenticator authn
    """


  Scenario: Attempting to use an invalid host API key to authenticate result in 401 error
    When I POST "/authn/cucumber/host%2Fapp/authenticate" with plain text body "wrong-api-key"
    Then the HTTP response status code is 401
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [auth@43868 authenticator="authn" user="cucumber:host:app"]
      [subject@43868 role="cucumber:host:app"]
      [action@43868 operation="authenticate" result="failure"]
      cucumber:host:app failed to authenticate with authenticator authn
    """

  Scenario: Attempting to use an invalid API key to authenticate with Accept-Encoding base64 result in 401 error
    When I authenticate Alice with Accept-Encoding header "base64" with plain text body "wrong-api-key"
    Then the HTTP response status code is 401
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [auth@43868 authenticator="authn" user="cucumber:user:alice"]
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
