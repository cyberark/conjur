Feature: Exchange a role's password for its API key

  Roles which have passwords can use the `login` method to obtain their API key.
  The API key is then used to authenticate and receive an auth token.

  Background:
    Given I create a new user "alice"
    And I have host "app"

  Scenario: Password can be used to obtain API key
    Given I set the password for "alice" to "My-Password1"
    When I can GET "/authn/cucumber/login" with username "alice" and password "My-Password1"
    Then the HTTP response content type is "text/plain"
    And the result is the API key for user "alice"
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [auth@43868 authenticator="authn" service="default:webservice:conjur/authn user="cucumber:user:alice"]
      [subject@43868 role="cucumber:user:alice"]
      [action@43868 operation="login" result="success"]
      cucumber:user:alice successfully logged in with authenticator authn service default:webservice:conjur/authn
    """

  Scenario: Password can be used by host to obtain API key
    Given I set the password for "host/app" to "My-Password1"
    When I GET "/authn/cucumber/login" with username "host/app" and password "My-Password1"
    Then the HTTP response content type is "text/plain"
    And the result is the API key for host "app"
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [auth@43868 authenticator="authn" service="default:webservice:conjur/authn user="cucumber:host:app"]
      [subject@43868 role="cucumber:host:app"]
      [action@43868 operation="login" result="success"]
      cucumber:host:app successfully logged in with authenticator authn service default:webservice:conjur/authn
    """

  Scenario: Wrong password cannot be used to obtain API key
    When I GET "/authn/cucumber/login" with username "alice" and password "Wrong-Password"
    Then the HTTP response status code is 401
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [subject@43868 role="cucumber:user:alice"]
      [auth@43868 authenticator="authn" service="cucumber:webservice:conjur/authn" user="cucumber:user:alice"]
      [client@43868 ip="172.17.0.1"]
      [action@43868 result="failure" operation="login"][meta sequenceId="1"]
      cucumber:user:alice failed to login with authenticator authn service cucumber:webservice:conjur/authn: CONJ00002E Invalid credentials
    """

  Scenario: Wrong password cannot be used by host to obtain API key
    When I GET "/authn/cucumber/login" with username "host/app" and password "Wrong-Password"
    Then the HTTP response status code is 401
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [subject@43868 role="cucumber:host:app"x]
      [auth@43868 authenticator="authn" service="cucumber:webservice:conjur/authn" user="cucumber:host:app"]
      [client@43868 ip="172.17.0.1"]
      [action@43868 result="failure" operation="login"][meta sequenceId="1"]
      cucumber:host:app failed to login with authenticator authn service cucumber:webservice:conjur/authn: CONJ00002E Invalid credentials
    """

  Scenario: Wrong username cannot be used to obtain API key
    When I set the password for "alice" to "My-Password1"
    And I GET "/authn/cucumber/login" with username "no-user" and password "My-Password1"
    Then the HTTP response status code is 401
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [subject@43868 role="cucumber:user:no-user"]
      [auth@43868 authenticator="authn" service="cucumber:webservice:conjur/authn" user="not-found"]
      [client@43868 ip="172.17.0.1"]
      [action@43868 result="failure" operation="login"][meta sequenceId="1"]
      cucumber:user:no-user failed to login with authenticator authn service cucumber:webservice:conjur/authn: CONJ00007E 'no-user' not found
    """

  Scenario: Wrong hostname cannot be used to obtain API key
    Given I set the password for "host/app" to "My-Password1"
    And I GET "/authn/cucumber/login" with username "host/no-host" and password "My-Password1"
    Then the HTTP response status code is 401
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [subject@43868 role="cucumber:host:no-host"]
      [auth@43868 authenticator="authn" service="cucumber:webservice:conjur/authn" user="not-found"]
      [client@43868 ip="172.17.0.1"]
      [action@43868 result="failure" operation="login"][meta sequenceId="1"]
      cucumber:host:no-host failed to login with authenticator authn service cucumber:webservice:conjur/authn: CONJ00007E 'no-host' not found
    """

  @logged-in
  Scenario: Bearer token cannot be used to login

    The login method requires the password; login cannot be performed using the auth token
    as a credential.

    When I GET "/authn/cucumber/login"
    Then the HTTP response status code is 401
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [subject@43868 role="cucumber:user:admin"]
      [auth@43868 authenticator="authn" service="cucumber:webservice:conjur/authn" user="cucumber:user:admin"]
      [client@43868 ip="172.17.0.1"]
      [action@43868 result="failure" operation="login"][meta sequenceId="1"]
      cucumber:user:admin failed to login with authenticator authn service cucumber:webservice:conjur/authn: CONJ00002E Invalid credentials
    """

  @logged-in-admin
  Scenario: "Super" users cannot login as other users

    Users can never login as other users.

    When I GET "/authn/cucumber/login?role=user:alice"
    Then the HTTP response status code is 401
