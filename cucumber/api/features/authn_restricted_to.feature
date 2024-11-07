@api
Feature: User and Host authentication can be network restricted

  Background:
    Given I am the super-user
    And I load a network-restricted policy

  @negative @acceptance
  Scenario: Request origin can deny access
    Given I save my place in the audit log file for remote
    When I authenticate as "alice" with account "cucumber"
    Then the HTTP response status code is 401
    And there is an audit record matching:
    """
      <84>1 * * conjur * authn
      [subject@43868 role="cucumber:user:alice"]
      [auth@43868 user="cucumber:user:alice" authenticator="authn" service="cucumber:webservice:conjur/authn"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="authenticate"]
      cucumber:user:alice failed to authenticate with authenticator authn service cucumber:webservice:conjur/authn: CONJ00003E User is not authorized to login from the current origin
    """

  @smoke
  Scenario: When the request origin is correct, then access is allowed
    When I authenticate as "bob" with account "cucumber"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/json"
