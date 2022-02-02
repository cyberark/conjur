@api
Feature: Exchange a role's password for its API key

  Roles which have passwords can use the `login` method to obtain their API key.
  The API key is then used to authenticate and receive an auth token.

  Background:
    Given I create a new user "alice"
    And I have host "app"

  @smoke
  Scenario: Password can be used to obtain API key
    Given I set the password for "alice" to "My-Password1"
    And I save my place in the audit log file for remote
    When I can GET "/authn/cucumber/login" with username "alice" and password "My-Password1"
    Then the HTTP response content type is "text/plain"
    And the result is the API key for user "alice"
    And there is an audit record matching:
    """
      <86>1 * * conjur * authn
      [subject@43868 role="cucumber:user:alice"]
      [auth@43868 user="cucumber:user:alice" authenticator="authn" service="cucumber:webservice:conjur/authn"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="login"]
      cucumber:user:alice successfully logged in with authenticator authn service cucumber:webservice:conjur/authn
    """

  @smoke
  Scenario: Password can be used by host to obtain API key
    Given I set the password for "host/app" to "My-Password1"
    And I save my place in the audit log file for remote
    When I GET "/authn/cucumber/login" with username "host/app" and password "My-Password1"
    Then the HTTP response content type is "text/plain"
    And the result is the API key for host "app"
    And there is an audit record matching:
    """
      <86>1 * * conjur * authn
      [subject@43868 role="cucumber:host:app"]
      [auth@43868 user="cucumber:host:app" authenticator="authn" service="cucumber:webservice:conjur/authn"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="login"]
      cucumber:host:app successfully logged in with authenticator authn service cucumber:webservice:conjur/authn
    """

  @negative @acceptance
  Scenario: Wrong password cannot be used to obtain API key
    Given I save my place in the audit log file for remote
    When I GET "/authn/cucumber/login" with username "alice" and password "Wrong-Password"
    Then the HTTP response status code is 401
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [subject@43868 role="cucumber:user:alice"]
      [auth@43868 user="cucumber:user:alice" authenticator="authn" service="cucumber:webservice:conjur/authn"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="login"]
      cucumber:user:alice failed to login with authenticator authn service cucumber:webservice:conjur/authn: CONJ00002E Invalid credentials
    """

  @negative @acceptance
  Scenario: Wrong password cannot be used by host to obtain API key
    Given I save my place in the audit log file for remote
    When I GET "/authn/cucumber/login" with username "host/app" and password "Wrong-Password"
    Then the HTTP response status code is 401
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [subject@43868 role="cucumber:host:app"]
      [auth@43868 user="cucumber:host:app" authenticator="authn" service="cucumber:webservice:conjur/authn"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="login"]
      cucumber:host:app failed to login with authenticator authn service cucumber:webservice:conjur/authn: CONJ00002E Invalid credentials
    """

  @negative @acceptance
  Scenario: Wrong username cannot be used to obtain API key
    Given I save my place in the audit log file for remote
    When I GET "/authn/cucumber/login" with username "non-exist" and password "My-Password1"
    Then the HTTP response status code is 401
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [subject@43868 role="cucumber:user:non-exist"]
      [auth@43868 user="not-found" authenticator="authn" service="cucumber:webservice:conjur/authn"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="login"]
      cucumber:user:non-exist failed to login with authenticator authn service cucumber:webservice:conjur/authn: CONJ00007E 'non-exist' not found
    """

  @negative @acceptance
  Scenario: Empty username results in 401 response
    When I GET "/authn/cucumber/login" with username "" and password "My-Password1"
    Then the HTTP response status code is 401

  @negative @acceptance
  Scenario: Invalid username with non-alpha characters results in 401 response
    When I GET "/authn/cucumber/login" with username "!@#$%^&*(){}" and password "My-Password1"
    Then the HTTP response status code is 401

  @negative @acceptance
  Scenario: Wrong hostname cannot be used to obtain API key
    Given I save my place in the audit log file for remote
    When I GET "/authn/cucumber/login" with username "host/non-exist" and password "My-Password1"
    Then the HTTP response status code is 401
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [subject@43868 role="cucumber:host:non-exist"]
      [auth@43868 user="not-found" authenticator="authn" service="cucumber:webservice:conjur/authn"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="login"]
      cucumber:host:non-exist failed to login with authenticator authn service cucumber:webservice:conjur/authn: CONJ00007E 'host/non-exist' not found
    """

  @negative @acceptance
  @logged-in
  Scenario: Bearer token cannot be used to login
    The login method requires the password; login cannot be performed using the auth token
    as a credential.

    Given I save my place in the audit log file for remote
    When I GET "/authn/cucumber/login"
    Then the HTTP response status code is 401

  @negative @acceptance
  @logged-in-admin
  Scenario: "Super" users cannot login as other users

    Users can never login as other users.

    When I GET "/authn/cucumber/login?role=user:alice"
    Then the HTTP response status code is 401
