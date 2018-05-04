Feature: Fetch resource details.

  Background:
    Given I am a user named "alice"
    And I create a new "variable" resource called "@namespace@/app-01.mycorp.com"

  Scenario: Showing a resource provides information about privileges, annotations and secrets on the resource

    Given I successfully POST "/secrets/cucumber/:resource_kind/:resource_id" with body:
    """
    the-value
    """
    And I create a new user "bob"
    And I permit user "bob" to "execute" it
    And I set annotation "description" to "Front end server"

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
      "id": "cucumber:variable:app-01.mycorp.com",
      "owner": "cucumber:user:alice",
      "permissions": [
      {
        "privilege": "execute",
        "role": "cucumber:user:bob"
      }
      ],
      "secrets": [
        {
          "version": 1
        }
      ]
    }
    """
