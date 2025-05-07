@api
Feature: Branches APIv2 tests - read one

  Background:
    Given I am the super-user
    And I can POST "/policies/cucumber/policy/root" with body from file "policy_cloud.yml"

  @acceptance
  Scenario: As admin I can get the root branch
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I save my place in the audit log file for remote
    And I can GET "/branches/cucumber/root"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "name": "root",
      "branch": "/",
      "owner": { "kind": "user", "id": "admin" },
      "annotations": {} }
    """
    And there is an audit record matching:
    """
    <85>1 * * conjur * branch\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="success" operation="get"]\s
    cucumber:user:admin successfully retrieved branch root with URI path: '/branches/cucumber/root'
    """

  @negative @acceptance
  Scenario: Trying to get a branch that the user does not have access to
    When I login as "alice@data-safe1"
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I can GET "/branches/cucumber/data/safe1/branch1"
    And the HTTP response status code is 200
    Then I login as "alice@data-safe1"
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I GET "/branches/cucumber/data/vault"
    And the HTTP response status code is 404
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "code": "404",
      "message": "Branch 'data/vault' not found in account 'cucumber'" }
    """

  @negative @acceptance
  Scenario: Cannot read branch with not existing parent branch
    And I am the super-user
    And I clear the "Accept" header
    And I clear the "Content-Type" header
    And I can PATCH "/policies/cucumber/policy/data/safe1/branch1" with body:
    """
    ---
    - !policy not_for_branch/branch2
    """
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I GET "/branches/cucumber/data/safe1/branch1/not_for_branch/branch2"
    Then the HTTP response status code is 404
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "code": "404",
    "message": "Branch 'data/safe1/branch1/not_for_branch' not found in account 'cucumber'" }
    """

  @acceptance
  Scenario: V2 header must be present
    Given I clear the "Accept" header
    And I GET "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 400
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "code": "400",
      "message": "CONJ00194W The api belongs to v2 APIs but it missing the version \"application/x.secretsmgr.v2beta+json\" in the Accept header" }
    """