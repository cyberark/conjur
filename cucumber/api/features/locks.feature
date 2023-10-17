@api
Feature: Adding and fetching secrets

  Background:
    Given I am the super-user
    And I successfully POST "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: conjur/locks
      body:
      - !webservice my-lock
    """

  @negative @acceptance
  Scenario: Attempting to get an expired lock

    Given I am the super-user
    And I DELETE "/locks/cucumber/my-lock"
    And I set the "Content-Type" header to "application/json"
    And I successfully POST "/locks/cucumber" with body:
    """
    {
      "id": "my-lock",
      "owner": "my-lock-owner",
      "ttl": 1
    }
    """
    When I wait for 2 seconds
    And I clear the "Content-Type" header
    And I GET "/locks/cucumber/my-lock"
    Then the HTTP response status code is 404
    And there is an error
    And the error message is "Lock not found"

  @acceptance
  Scenario: Attempting to get an existing lock

    Given I am the super-user
    And I DELETE "/locks/cucumber/my-lock"
    And I set the "Content-Type" header to "application/json"
    And I successfully POST "/locks/cucumber" with body:
    """
    {
      "id": "my-lock",
      "owner": "my-lock-owner",
      "ttl": 20
    }
    """
    And I clear the "Content-Type" header
    And I successfully GET "/locks/cucumber/my-lock"
    Then the HTTP response status code is 200

  @negative @acceptance
  Scenario: Attempting to delete an expired lock

    Given I am the super-user
    And I DELETE "/locks/cucumber/my-lock"
    And I set the "Content-Type" header to "application/json"
    And I successfully POST "/locks/cucumber" with body:
    """
    {
      "id": "my-lock",
      "owner": "my-lock-owner",
      "ttl": 1
    }
    """
    When I wait for 2 seconds
    And I clear the "Content-Type" header
    And I DELETE "/locks/cucumber/my-lock"
    Then the HTTP response status code is 404
    And there is an error
    And the error message is "Lock not found"

  @acceptance
  Scenario: Attempting to delete an existing lock

    Given I am the super-user
    And I DELETE "/locks/cucumber/my-lock"
    And I set the "Content-Type" header to "application/json"
    And I successfully POST "/locks/cucumber" with body:
    """
    {
      "id": "my-lock",
      "owner": "my-lock-owner",
      "ttl": 20
    }
    """
    When I clear the "Content-Type" header
    And I successfully DELETE "/locks/cucumber/my-lock"
    Then the HTTP response status code is 200

  @acceptance
  Scenario: Attempting to update an existing lock

    Given I am the super-user
    And I DELETE "/locks/cucumber/my-lock"
    And I set the "Content-Type" header to "application/json"
    And I successfully POST "/locks/cucumber" with body:
    """
    {
      "id": "my-lock",
      "owner": "my-lock-owner",
      "ttl": 20
    }
    """
    And the JSON response field "created_at" is equal to field "modified_at"
    When I successfully PATCH "/locks/cucumber/my-lock" with body:
    """
    {
      "ttl": 10
    }
    """
    Then the HTTP response status code is 200
    And the JSON response field "created_at" is not equal to field "modified_at"
    And the JSON response field "modified_at" is not equal to field "expires_at"

  @acceptance
  Scenario: Attempting to update an expired lock

    Given I am the super-user
    And I DELETE "/locks/cucumber/my-lock"
    And I set the "Content-Type" header to "application/json"
    And I successfully POST "/locks/cucumber" with body:
    """
    {
      "id": "my-lock",
      "owner": "my-lock-owner",
      "ttl": 1
    }
    """
    When I wait for 2 seconds
    And I successfully PATCH "/locks/cucumber/my-lock" with body:
    """
    {
      "ttl": 10
    }
    """
    Then the HTTP response status code is 404
    And there is an error
    And the error message is "Lock not found"
