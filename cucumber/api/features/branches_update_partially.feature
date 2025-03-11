@api
Feature: Branches APIv2 tests - patch

  Background:
    Given I am the super-user
    And I can POST "/policies/cucumber/policy/root" with body from file "policy_cloud.yml"

  @acceptance
  Scenario: As admin I can update owner of a branch
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I can GET "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "name": "branch1", "branch": "data/safe1",
      "owner": { "kind": "group", "id": "data/data-group" },
      "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "123" } }
    """
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I save my place in the audit log file for remote
    And I can PATCH "/branches/cucumber/data/safe1/branch1" with body:
    """
    { "owner": { "kind": "user", "id": "admin" } }
    """
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "name": "branch1",
      "branch": "data/safe1",
      "owner": { "kind": "user", "id": "admin" },
      "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "123" } }
    """
#    And there is an audit record matching:
#    """
#    <85>1 * * conjur * branch\s
#    [auth@43868 user="cucumber:user:admin"]
#    [subject@43868 edge=""]
#    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
#    [action@43868 result="success" operation="update"]\s
#    cucumber:user:admin successfully created branch branch1-in-root with URI path: '/branches/cucumber/data/safe1/branch1' and JSON object: {"owner":{"kind":"user","id":"admin"}}
#    """
    And I clear the "Content-Type" header
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I can GET "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "name": "branch1", "branch": "data/safe1",
      "owner": { "kind": "user", "id": "admin" },
      "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "123" } }
    """

  @acceptance
  Scenario: As admin I can update annotation for a branch
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I can GET "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "name": "branch1", "branch": "data/safe1",
      "owner": { "kind": "group", "id": "data/data-group" },
      "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "123" } }
    """
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I save my place in the audit log file for remote
    And I can PATCH "/branches/cucumber/data/safe1/branch1" with body:
    """
    { "annotations": { "branch1-ann-2": "222", "branch1-ann-3": "333" } }
    """
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "name": "branch1",
      "branch": "data/safe1",
      "owner": { "kind": "group", "id": "data/data-group" },
      "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "222", "branch1-ann-3": "333" } }
    """
#    And there is an audit record matching:
#    """
#    <85>1 * * conjur * branch\s
#    [auth@43868 user="cucumber:user:admin"]
#    [subject@43868 edge=""]
#    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
#    [action@43868 result="success" operation="update"]\s
#    cucumber:user:admin successfully created branch branch1-in-root with URI path: '/branches/cucumber/data/safe1/branch1' and JSON object: {"owner":{"kind":"user","id":"admin"}}
#    """
    And I clear the "Content-Type" header
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I can GET "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "name": "branch1",
      "branch": "data/safe1",
      "owner": { "kind": "group", "id": "data/data-group" },
      "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "222", "branch1-ann-3": "333" } }
    """

  @acceptance
  Scenario: As admin I can update owner and annotation for a branch
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I can GET "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "name": "branch1", "branch": "data/safe1",
      "owner": { "kind": "group", "id": "data/data-group" },
      "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "123" } }
    """
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I save my place in the audit log file for remote
    And I can PATCH "/branches/cucumber/data/safe1/branch1" with body:
    """
    { "owner": { "kind": "user", "id": "admin" },
      "annotations": { "branch1-ann-2": "222", "branch1-ann-3": "333" } }
    """
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "name": "branch1",
      "branch": "data/safe1",
      "owner": { "kind": "user", "id": "admin" },
      "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "222", "branch1-ann-3": "333" } }
    """
#    And there is an audit record matching:
#    """
#    <85>1 * * conjur * branch\s
#    [auth@43868 user="cucumber:user:admin"]
#    [subject@43868 edge=""]
#    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
#    [action@43868 result="success" operation="update"]\s
#    cucumber:user:admin successfully created branch branch1-in-root with URI path: '/branches/cucumber/data/safe1/branch1' and JSON object: {"owner":{"kind":"user","id":"admin"}}
#    """
    And I clear the "Content-Type" header
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I can GET "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "name": "branch1",
      "branch": "data/safe1",
      "owner": { "kind": "user", "id": "admin" },
      "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "222", "branch1-ann-3": "333" } }
    """

  @negative @acceptance
  Scenario: As admin I cannot update using no body
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I save my place in the audit log file for remote
    And I PATCH "/branches/cucumber/data/safe1/branch1" with body:
    """
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "code": "422",
      "message": "Unable to parse request json body: " }
    """

  @negative @acceptance
  Scenario: As admin I cannot update using empty body
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I save my place in the audit log file for remote
    And I PATCH "/branches/cucumber/data/safe1/branch1" with body:
    """
    { }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "code": "422",
      "message": "Empty request body" }
    """

  @acceptance
  Scenario: As admin I cannot update using unsupported param
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I can GET "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "name": "branch1", "branch": "data/safe1",
      "owner": { "kind": "group", "id": "data/data-group" },
      "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "123" } }
    """
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I save my place in the audit log file for remote
    And I PATCH "/branches/cucumber/data/safe1/branch1" with body:
    """
    { "foo": "bar" }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "code": "422",
      "message": "Invalid input field: foo" }
    """
    And I PATCH "/branches/cucumber/data/safe1/branch1" with body:
    """
    { "foo": "bar",
     "owner": { "kind": "user", "id": "admin" } }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "code": "422",
      "message": "Invalid input field: foo" }
    """
    And I PATCH "/branches/cucumber/data/safe1/branch1" with body:
    """
    { "foo": "bar",
      "annotations": { "mykey1": "def", "mynewkey": "qwer" } }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "code": "422",
      "message": "Invalid input field: foo" }
    """
    And I PATCH "/branches/cucumber/data/safe1/branch1" with body:
    """
    { "foo": "bar",
      "owner": { "kind": "user", "id": "admin" },
      "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "123" } }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "code": "422",
      "message": "Invalid input field: foo" }
    """

  @negative @acceptance
  Scenario: Cannot update a branch without privileges
    And I login as "alice@data-safe1"
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I PATCH "/branches/cucumber/data/safe1/branch1/alice-execute-only" with body:
    """
    { "owner": { "kind": "user", "id": "admin" } }
    """
    Then the HTTP response status code is 404
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "code": "404",
      "message": "Branch 'data/safe1/branch1/alice-execute-only' not found in account 'cucumber'" }
    """

  @negative @acceptance
  Scenario: Cannot update a branch with not existing parent branch
    And I am the super-user
    And I clear the "Accept" header
    And I clear the "Content-Type" header
    And I can PATCH "/policies/cucumber/policy/data/safe1/branch1" with body:
    """
    ---
    - !policy not_for_branch/branch2
    """
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I PATCH "/branches/cucumber/data/safe1/branch1/not_for_branch/branch2" with body:
    """
    { "owner": { "kind": "user", "id": "admin" },
      "annotations": { "branch1-ann-2": "222", "branch1-ann-3": "333" } }
    """
    Then the HTTP response status code is 404
    And the result as json is:
    """
    { "code": "404",
      "message": "Branch 'data/safe1/branch1/not_for_branch' not found in account 'cucumber'" }
    """

  @acceptance
  Scenario: V2 header must be present
    Given I clear the "Accept" header
    And I PATCH "/branches/cucumber/data/safe1/branch1" with body:
    """
    { "owner": { "kind": "user", "id": "admin" } }
    """
    Then the HTTP response status code is 400
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the result as json is:
    """
    { "code": "400",
      "message": "CONJ00194W The api belongs to v2 APIs but it missing the version \"application/x.secretsmgr.v2beta+json\" in the Accept header" }
    """