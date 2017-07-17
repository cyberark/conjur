@logged-in
Feature: Batch retrieval of secrets
  Background:
    Given I create a new "variable" resource called "secret1"
    And I add the secret value "s1" to the current resource
    And I create a new "variable" resource called "secret2"
    And I add the secret value "s2" to the current resource

  Scenario: Returns a JSON hash mapping resource id to value
    When I GET "/secrets?resource_ids=cucumber:variable:secret1,cucumber:variable:secret2"
    Then the JSON should be:
    """
    { "cucumber:variable:secret1": "s1", "cucumber:variable:secret2": "s2" }
    """

  Scenario: Fails with 403 if execute privilege is not held
    When I am a user named "someone-else"
    And I GET "/secrets?resource_ids=cucumber:variable:secret1"
    Then the HTTP response status code is 403

  Scenario: Fails with 404 if a resource doesn't exist
    When I GET "/secrets?resource_ids=cucumber:variable:secret1,cucumber:variable:not-a-secret"
    Then the HTTP response status code is 404

  Scenario: Fails with 404 if a resource doesn't have a value
    Given I create a new "variable" resource called "secret-no-value"
    When I GET "/secrets?resource_ids=cucumber:variable:secret1,cucumber:variable:secret-no-value"
    Then the HTTP response status code is 404

  Scenario: Is order dependent...?
