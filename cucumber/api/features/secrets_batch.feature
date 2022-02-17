@api
Feature: Batch retrieval of secrets
  Background:
    Given I am a user named "bob"
    Given I create a new "variable" resource called "secret1"
    And I add the secret value "s1" to the resource "cucumber:variable:secret1"
    And I create a new "variable" resource called "secret2"
    And I add the secret value "s2" to the resource "cucumber:variable:secret2"
    And I create a new "variable" resource called "secret3"
    And I add the secret value "s3" to the resource "cucumber:variable:secret3"

  @smoke
  Scenario: Returns a JSON hash mapping resource id to value
    Given I save my place in the audit log file for remote
    When I GET "/secrets?variable_ids=cucumber:variable:secret1,cucumber:variable:secret2"
    Then the JSON should be:
    """
    { "cucumber:variable:secret1": "s1", "cucumber:variable:secret2": "s2" }
    """
    And there is an audit record matching:
    """
      <86>1 * * conjur * fetch
      [auth@43868 user="cucumber:user:bob"]
      [subject@43868 resource="cucumber:variable:secret1"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="fetch"]
      cucumber:user:bob fetched cucumber:variable:secret1
    """
    And there is an audit record matching:
    """
      <86>1 * * conjur * fetch
      [auth@43868 user="cucumber:user:bob"]
      [subject@43868 resource="cucumber:variable:secret2"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="fetch"]
      cucumber:user:bob fetched cucumber:variable:secret2
    """

  @negative @acceptance
  Scenario: Fails with 422 if variable_ids param is missing
    When I GET "/secrets"
    Then the HTTP response status code is 422

  @negative @acceptance
  Scenario: Fails with 422 if variable_ids param is empty
    When I GET "/secrets?variable_ids="
    Then the HTTP response status code is 422

  @negative @acceptance
  Scenario: Fails with 422 if variable_ids param has only blank items
    When I GET "/secrets?variable_ids=,,,"
    Then the HTTP response status code is 422

  @negative @acceptance
  Scenario: Fails with 403 if execute privilege is not held
    When I am a user named "someone-else"
    And I GET "/secrets?variable_ids=cucumber:variable:secret1"
    Then the HTTP response status code is 403

  @negative @acceptance
  Scenario: Fails with 404 if variable_ids param has some blank items
    When I GET "/secrets?variable_ids=cucumber:variable:secret1,,,cucumber:variable:secret2"
    Then the HTTP response status code is 422
    And there is an error
    And the error message is "variable_ids"

  @negative @acceptance
  Scenario: Fails with 404 if a variable_id param is of an incorrect format
    When I GET "/secrets?variable_ids=1,2,3"
    Then the HTTP response status code is 404
    And there is an error
    And the error message is "CONJ00076E Variable 1 is empty or not found."

  @negative @acceptance
  Scenario: Fails with 404 if a resource doesn't exist
    When I GET "/secrets?variable_ids=cucumber:variable:secret1,cucumber:variable:not-a-secret"
    Then the HTTP response status code is 404
    And there is an error
    And the error message is "CONJ00076E Variable cucumber:variable:not-a-secret is empty or not found."

  @negative @acceptance
  Scenario: Fails with 404 if a resource doesn't have a value
    Given I create a new "variable" resource called "secret-no-value"
    When I GET "/secrets?variable_ids=cucumber:variable:secret1,cucumber:variable:secret-no-value"
    Then the HTTP response status code is 404
    And there is an error
    And the error message is "CONJ00076E Variable cucumber:variable:secret-no-value is empty or not found."

  # This test explicitly tests an error case that was discovered in Conjur v4 where
  # resource IDs were matched with incorrect variable values in the JSON response.
  # It was fixed in: https://github.com/conjurinc/core/pull/46/files
  @smoke
  Scenario: Returns a correct mapping of resource ids to secret values
    Given I add the secret value "v1" to the resource "cucumber:variable:secret1"
    And I add the secret value "v2" to the resource "cucumber:variable:secret2"
    And I add the secret value "v3" to the resource "cucumber:variable:secret1"
    And I add the secret value "v4" to the resource "cucumber:variable:secret3"
    And I add the secret value "v5" to the resource "cucumber:variable:secret2"
    And I add the secret value "v6" to the resource "cucumber:variable:secret3"
    When I GET "/secrets?variable_ids=cucumber:variable:secret1,cucumber:variable:secret2,cucumber:variable:secret3"
    Then the JSON should be:
    """
    { "cucumber:variable:secret1": "v3", "cucumber:variable:secret2": "v5", "cucumber:variable:secret3": "v6" }
    """
    When I GET "/secrets?variable_ids=cucumber:variable:secret3,cucumber:variable:secret2,cucumber:variable:secret1"
    Then the JSON should be:
    """
    { "cucumber:variable:secret1": "v3", "cucumber:variable:secret2": "v5", "cucumber:variable:secret3": "v6" }
    """
    When I GET "/secrets?variable_ids=cucumber:variable:secret2,cucumber:variable:secret3,cucumber:variable:secret1"
    Then the JSON should be:
    """
    { "cucumber:variable:secret1": "v3", "cucumber:variable:secret2": "v5", "cucumber:variable:secret3": "v6" }
    """

  @smoke
  Scenario: Returns Base64 encoded secrets with Accept-Encoding header base64
    Given I create a binary secret value for resource "cucumber:variable:secret3"
    And I add the secret value "v2" to the resource "cucumber:variable:secret2"
    And I set the "Accept-Encoding" header to "base64"
    When I GET "/secrets?variable_ids=cucumber:variable:secret3,cucumber:variable:secret2"
    Then the binary data is preserved for "cucumber:variable:secret3"
    And the content encoding is "base64"

  @smoke
  Scenario: Returns Base64 encoded secrets with alternate heading capitalization
    Given I create a binary secret value for resource "cucumber:variable:secret3"
    And I set the "Accept-Encoding" header to "Base64"
    When I GET "/secrets?variable_ids=cucumber:variable:secret3"
    Then the binary data is preserved for "cucumber:variable:secret3"

  @negative @acceptance
  Scenario: Fails with 406 on retrieval of single binary secret with improper header
    Given I create a binary secret value for resource "cucumber:variable:secret3"
    And I set the "Accept-Encoding" header to "*"
    When I GET "/secrets?variable_ids=cucumber:variable:secret3"
    Then the HTTP response status code is 406

  @negative @smoke
  Scenario: Fails with 406 on retrieval of multiple secrets with improper header
    Given I create a binary secret value for resource "cucumber:variable:secret3"
    And I add the secret value "v2" to the resource "cucumber:variable:secret2"
    And I set the "Accept-Encoding" header to "*"
    When I GET "/secrets?variable_ids=cucumber:variable:secret3,cucumber:variable:secret2"
    Then the HTTP response status code is 406

  @acceptance
  Scenario: Omit the Accept-Encoding header entirely from batch secrets request
    Given I add the secret value "v2" to the resource "cucumber:variable:secret2"
    When I GET "/secrets?variable_ids=cucumber:variable:secret2" with no default headers
    Then the JSON should be:
    """
    { "cucumber:variable:secret2": "v2" }
    """
