@api
Feature: Branches APIv2 tests - create empty

  Background:
    Given I am the super-user
    And I can POST "/policies/cucumber/policy/root" with body from file "policy_cloud.yml"

  @acceptance
  Scenario: As admin I can create a branch with owner in root
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I save my place in the audit log file for remote
    And I can POST "/branches/cucumber" with body:
    """
    { "name": "branch1",
      "branch": "/",
      "owner": { "kind": "user", "id": "admin" } }
    """
    And there is an audit record matching:
    """
    <85>1 * * conjur * branch\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="success" operation="create"]\s
    cucumber:user:admin successfully created branch branch1 with URI path: '/branches/cucumber' and JSON object: {"name":"branch1","branch":"/","owner":{"kind":"user","id":"admin"}}
    """
    Then the HTTP response status code is 201
    And I clear the "Content-Type" header
    And I save my place in the audit log file for remote
    And I can GET "/branches/cucumber/branch1"
    And the HTTP response status code is 200
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "name": "branch1",
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
    cucumber:user:admin successfully retrieved branch branch1 with URI path: '/branches/cucumber/branch1'
    """

  @negative @acceptance
  Scenario: Cannot create a branch using existing name
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name" : "data",
      "branch": "/" }
    """
    Then the HTTP response status code is 409
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "code": "409",
      "message": "Branch \"cucumber:branch:data\" already exists" }
    """

  @negative @acceptance
  Scenario: Cannot create a branch using owner with empty string as values
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name" : "data",
      "branch": "/",
      "owner": { "kind": "", "id": "" } }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "code": "422",
      "message": "Kind can't be blank, Kind '' is not a valid owner kind, Id can't be blank, Id Wrong path '', and Id is too short (minimum is 1 character)" }
    """

  @negative @acceptance
  Scenario: Cannot create a branch without name
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "branch": "/" }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "code": "422",
      "message": "Name can't be blank, Name is too short (minimum is 1 character), and Name Wrong name ''" }
    """

  @negative @acceptance
  Scenario: Cannot create a branch without parent branch
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch1" }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "code": "422",
      "message": "Branch can't be blank, Branch can't be blank, Branch can't be blank, Branch is too short (minimum is 1 character), and Branch Wrong path ''" }
    """

  @acceptance
  Scenario: Creating a branch with annotation containing JSON
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I can POST "/branches/cucumber" with body:
    """
    { "name": "branch2",
      "branch": "data/safe1",
      "annotations": {
        "branch2-ann-key1": "{ \"foo\": \"bar\", \"baz\": 1 }",
        "branch2-ann-key2": "branch2-ann-val2" } }
    """
    And the HTTP response status code is 201
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "name": "branch2",
      "branch": "data/safe1",
      "owner": { "kind": "policy", "id": "data/safe1" },
      "annotations": {
        "branch2-ann-key1": "{ \"foo\": \"bar\", \"baz\": 1 }",
        "branch2-ann-key2": "branch2-ann-val2" } }
    """

  @negative @acceptance
  Scenario: Cannot create a branch with wrong value in annotations value
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I save my place in the audit log file for remote
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch2",
      "branch": "data/safe2",
      "annotations": { "branch2-ann-key1": 6, "branch2-ann-key2": "branch2-ann-val2" } }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "code": "422",
      "message": "Branch2-ann-key1 should have string value but got 6" }
    """

  @negative @acceptance
  Scenario: Cannot create a branch using not existing parent
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch2",
      "branch": "data/safe2",
      "annotations": {
        "branch2-ann-key1": "branch2-ann-val1",
        "branch2-ann-key2": "branch2-ann-val2" } }
    """
    Then the HTTP response status code is 404
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "code": "404",
      "message": "Branch 'data/safe2' not found in account 'cucumber'" }
    """

  @acceptance
  Scenario: As admin I can create a branch with owner
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch2", "branch": "data/safe1",
      "owner": { "kind": "group", "id": "data/data-group" },
      "annotations": { "mykey1": "abc", "mykeyffsdfs": "dfdsfsf" } }
    """
    Then the HTTP response status code is 201
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "name": "branch2", "branch": "data/safe1",
      "owner": { "kind": "group", "id": "data/data-group" },
      "annotations": { "mykey1": "abc", "mykeyffsdfs": "dfdsfsf" } }
    """

  @acceptance
  Scenario: As admin I can create a branch with admin owner
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch2", "branch": "/",
      "owner": { "kind": "user", "id": "admin" },
      "annotations": { "mykey1": "abc", "mykeyffsdfs": "dfdsfsf" } }
    """
    Then the HTTP response status code is 201
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "name": "branch2", "branch": "/",
      "owner": { "kind": "user", "id": "admin" },
      "annotations": { "mykey1": "abc", "mykeyffsdfs": "dfdsfsf" } }
    """

  @negative @acceptance
  Scenario: As admin I cannot create a branch with not existing owner
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch2", "branch": "data/safe1",
      "owner": { "kind": "group", "id": "data/data-group-nope" },
      "annotations": { "mykey1": "abc", "mykeyffsdfs": "dfdsfsf" } }
    """
    Then the HTTP response status code is 404
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "code": "404",
      "message": "Group 'data/data-group-nope' not found in account 'cucumber'" }
    """

  @acceptance
  Scenario: Getting the branch that the user has access to
    When I login as "alice@data-safe1"
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I can GET "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 200
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "name": "branch1",
      "branch": "data/safe1",
      "owner": { "kind": "group", "id": "data/data-group" },
      "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "123" } }
    """

  @acceptance
  Scenario: A user with permission to creation in parent can create branch in it
    When I login as "alice@data-safe1"
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I can POST "/branches/cucumber" with body:
    """
    { "name": "alicebranch",
      "branch": "data/safe1/branch1" }
    """
    Then the HTTP response status code is 201
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"

  @negative @acceptance
  Scenario: Cannot create branch without permission to the parent
    When I login as "alice@data-safe1"
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "alicebranch",
      "branch": "data/safe1/alice-read-only" }
    """
    Then the HTTP response status code is 404
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "code": "404",
      "message": "Branch 'data/safe1/alice-read-only' not found in account 'cucumber'" }
    """

  @negative @acceptance
  Scenario: Cannot create branch using existing name but policy is not visible
    And I am the super-user
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I can POST "/branches/cucumber" with body:
    """
    { "name": "alice-hidden",
      "branch": "data/safe1/branch1" }
    """
    When I login as "alice@data-safe1"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "alice-hidden",
      "branch": "data/safe1/branch1" }
    """
    Then the HTTP response status code is 409
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "code": "409",
      "message": "Branch \"cucumber:branch:data/safe1/branch1/alice-hidden\" already exists" }
    """

  @negative @acceptance
  Scenario: Cannot create branch using not existing user
    When I log out
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch2",
      "branch": "data/safe1" }
    """
    Then the HTTP response status code is 401
#    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the response is empty

  @negative @acceptance
  Scenario: Cannot create a branch with not existing parent branch
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
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch22",
      "branch": "data/safe1/branch1/not_for_branch/branch2" }
    """
    Then the HTTP response status code is 404
    And the JSON should be:
    """
    { "code": "404",
      "message": "Branch 'data/safe1/branch1/not_for_branch' not found in account 'cucumber'" }
    """

  @acceptance
  Scenario: V2 header must be present
    Given I clear the "Accept" header
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch1",
      "branch": "/",
      "owner": { "kind": "user", "id": "admin" } }
    """
    Then the HTTP response status code is 400
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "code": "400",
      "message": "CONJ00194W The api belongs to v2 APIs but it missing the version \"application/x.secretsmgr.v2beta+json\" in the Accept header" }
    """
