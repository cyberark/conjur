@api
Feature: Fetch resource details.

  Background:
    Given I am a user named "alice"
    And I create a new "variable" resource called "@namespace@/app-01.mycorp.com"

  @smoke
  Scenario: Showing a resource provides information about privileges, annotations and secrets on the resource

    Given I successfully POST "/secrets/cucumber/:resource_kind/:resource_id" with body:
    """
    the-value
    """
    And I create a new user "bob"
    And I permit user "bob" to "execute" it
    And I set annotation "description" to "Front end server"
    Given I save my place in the audit log file for remote
    When I successfully GET "/resources/cucumber/:resource_kind/:resource_id"
    Then the JSON should be:
    """
    {
      "annotations" : [
        {
          "name": "description",
          "value": "Front end server"
        }
      ],
      "id": "cucumber:variable:@namespace@/app-01.mycorp.com",
      "owner": "cucumber:user:alice",
      "permissions": [
      {
        "privilege": "execute",
        "role": "cucumber:user:bob"
      }
      ],
      "secrets": [
        {
          "version": 1,
          "expires_at": null
        }
      ]
    }
    """
    And there is an audit record matching:
    """
      <86>1 * * conjur * resource
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 resource="cucumber:variable:@namespace@/app-01.mycorp.com"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="get"]
      cucumber:user:alice successfully fetched resource details.
    """

  @negative @acceptance
  Scenario: Trying to show a resource that does not exist
    Given I save my place in the audit log file for remote
    When I GET "/resources/cucumber/santa/claus"
    Then the HTTP response status code is 404
    And there is an audit record matching:
    """
      <84>1 * * conjur * resource
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 resource="cucumber:santa:claus"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="get"]
      cucumber:user:alice failed to fetch resource details: Santa 'claus' not found in account 'cucumber'
    """

  @negative @acceptance
  Scenario: Trying to show a resource that does not exist with no audit
    Given I set the "X_FORWARDED_FOR" header to "127.0.0.1"
    And I save my place in the audit log file for remote
    When I GET "/resources/cucumber/santa/noclaus?show_audit=false"
    Then the HTTP response status code is 404
    And there is no audit record matching:
    """
      <84>1 * * conjur * resource
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 resource="cucumber:santa:noclaus"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="get"]
      cucumber:user:alice failed to fetch resource details: Santa 'noclaus' not found in account 'cucumber'
    """