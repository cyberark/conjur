@api
Feature: Custom Authenticators can obtain access tokens for any role

  @smoke
  Scenario: Obtain an access token for a user
    When I request from authn-local:
    """
    { "account" : "cucumber", "sub" : "alice" }
    """
    Then I obtain an access token for "alice" in account "cucumber"

  @smoke
  Scenario: Obtain an access token for a host
    When I request from authn-local:
    """
    { "account" : "cucumber", "sub" : "host/myapp-01" }
    """
    Then I obtain an access token for "host/myapp-01" in account "cucumber"

  @acceptance
  Scenario: Custom expiration time can be specified.
    When I request from authn-local:
    """
    { "account" : "cucumber", "sub" : "alice", "exp" : 1512664254 }
    """
    Then the access token expires at 1512664254

  @negative @acceptance
  Scenario: Sending invalid input results in an empty response
    When I request from authn-local:
    """
    foobar
    """
    Then the response is empty
