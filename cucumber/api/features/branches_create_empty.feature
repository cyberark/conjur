@api
Feature: Branches APIv2 tests - create empty

  Background:
    Given I am the super-user
    And I can POST "/policies/cucumber/policy/root" with body from file "policy_data.yml"

  @acceptance
  Scenario: As admin I can create a branch with owner in root
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I save my place in the audit log file for remote
    When I can POST "/branches/cucumber" with body:
    """
    { "name": "branch1",
      "branch": "/",
      "owner": { "kind": "user", "id": "admin" } }
    """
    Then there is an audit record matching:
    """
    <85>1 * * conjur * branch\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="success" operation="create"]\s
    cucumber:user:admin successfully created branch branch1 with URI path: '/branches/cucumber' and JSON object: {"name":"branch1","branch":"/","owner":{"kind":"user","id":"admin"}}
    """
    And the HTTP response status code is 201
    And I clear the "Content-Type" header
    And I can GET "/branches/cucumber/branch1"
    And the HTTP response status code is 200
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "name": "branch1",
      "branch": "/",
      "owner": { "kind": "user", "id": "admin" },
      "annotations": {} }
    """

  @acceptance
  Scenario: As admin I can create a branch with owner
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I save my place in the audit log file for remote
    When I can POST "/branches/cucumber" with body:
    """
    { "name": "branch1",
      "branch": "/",
      "owner": { "kind": "user", "id": "bob" } }
    """
    Then there is an audit record matching:
    """
    <85>1 * * conjur * branch\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="success" operation="create"]\s
    cucumber:user:admin successfully created branch branch1 with URI path: '/branches/cucumber' and JSON object: {"name":"branch1","branch":"/","owner":{"kind":"user","id":"bob"}}
    """
    And the HTTP response status code is 201
    And I clear the "Content-Type" header
    And I can GET "/branches/cucumber/branch1"
    And the HTTP response status code is 200
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "name": "branch1",
      "branch": "/",
      "owner": { "kind": "user", "id": "bob" },
      "annotations": {} }
    """

  @negative @acceptance
  Scenario: Cannot create a branch using existing name
    Given I set the Accept header to APIv2
    And I set the Accept header to APIv2
    And I save my place in the audit log file for remote
    And I set the "Content-Type" header to "application/json"
    When I POST "/branches/cucumber" with body:
    """
    { "name" : "data",
      "branch": "/" }
    """
    Then the HTTP response status code is 409
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "409",
      "message": "Branch \"cucumber:branch:data\" already exists" }
    """
    And there is an audit record matching:
    """
    <85>1 * * conjur * branch\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="failure" operation="create"]\s
    cucumber:user:admin failed to create branch data with URI path: '/branches/cucumber' and JSON object: {"name":"data","branch":"/"}: Branch "cucumber:branch:data" already exists
    """

  @negative @acceptance
  Scenario: Cannot create a branch using nested parent path more than 15
    Given I set the Accept header to APIv2
    And I set the Accept header to APIv2
    And I save my place in the audit log file for remote
    And I set the "Content-Type" header to "application/json"
    When I POST "/branches/cucumber" with body:
    """
    { "name" : "test-branch",
      "branch": "/data/sub/sub/sub/sub/sub/sub/sub/sub/sub/sub/sub/sub/sub/sub/branch" }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "422",
      "message": "The number of identifier nesting exceeds maximum depth of 15" }
    """

  @negative @acceptance
  Scenario: Cannot create a branch using owner with empty string as values
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    When I POST "/branches/cucumber" with body:
    """
    { "name" : "data",
      "branch": "/",
      "owner": { "kind": "", "id": "" } }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "422",
      "message": "Kind can't be blank, Kind '' is not a valid owner kind, Id can't be blank, Id Wrong path '', and Id is too short (minimum is 1 character)" }
    """

  @negative @acceptance
  Scenario: Cannot create a branch without name
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    When I POST "/branches/cucumber" with body:
    """
    { "branch": "/" }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "422",
      "message": "CONJ00190W Missing required parameter: name" }
    """

  @negative @acceptance
  Scenario: Cannot create a branch without parent branch
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    When I POST "/branches/cucumber" with body:
    """
    { "name": "branch1" }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "422",
      "message": "CONJ00190W Missing required parameter: branch" }
    """

  @negative @acceptance
  Scenario: Cannot create a branch with wrong chars in parent branch
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    When I POST "/branches/cucumber" with body:
    """
    { "name": "branch1",
      "branch": "data/safe1<wrong>" }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "422",
      "message": "Branch Wrong path 'data/safe1<wrong>'" }
    """

  @acceptance
  Scenario: Creating a branch with annotation containing JSON
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    When I can POST "/branches/cucumber" with body:
    """
    { "name": "branch2",
      "branch": "data/safe1",
      "annotations": {
        "branch2-ann-key1": "{ \"foo\": \"bar\", \"baz\": 1 }",
        "branch2-ann-key2": "branch2-ann-val2" } }
    """
    Then the HTTP response status code is 201
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "name": "branch2",
      "branch": "data/safe1",
      "owner": { "kind": "policy", "id": "data/safe1" },
      "annotations": {
        "branch2-ann-key1": "{ \"foo\": \"bar\", \"baz\": 1 }",
        "branch2-ann-key2": "branch2-ann-val2" } }
    """

  @acceptance
  Scenario: Creating a branch giving absolute path
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    When I can POST "/branches/cucumber" with body:
    """
    { "name": "branch2",
      "branch": "/data/safe1",
      "annotations": {
        "branch2-ann-key1": "{ \"foo\": \"bar\", \"baz\": 1 }",
        "branch2-ann-key2": "branch2-ann-val2" } }
    """
    Then the HTTP response status code is 201
    And the HTTP response content type is APIv2
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
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    When I POST "/branches/cucumber" with body:
    """
    { "name": "branch2",
      "branch": "data/safe2",
      "annotations": { "branch2-ann-key1": 6, "branch2-ann-key2": "branch2-ann-val2" } }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "422",
      "message": "Branch2-ann-key1 should have string value but got 6" }
    """

  @negative @acceptance
  Scenario: Cannot create a branch using not existing parent
    When I set the Accept header to APIv2
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
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "404",
      "message": "Branch 'data/safe2' not found in account 'cucumber'" }
    """

  @negative @acceptance
  Scenario: Cannot create a branch using not supported param in body
    When I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch2",
      "branch": "data",
      "not_supported1": "should be error1!",
      "not_supported2": "should be error2!",
      "annotations": {
        "branch2-ann-key1": "branch2-ann-val1",
        "branch2-ann-key2": "branch2-ann-val2" } }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "422",
      "message": "Unexpected parameters: not_supported1, not_supported2" }
    """

  @negative @acceptance
  Scenario: Cannot create a branch using not supported param in query
    When I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber?notpermitted=foobar" with body:
    """
    { "name": "branch2",
      "branch": "data",
      "annotations": {
        "branch2-ann-key1": "branch2-ann-val1",
        "branch2-ann-key2": "branch2-ann-val2" } }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "422",
      "message": "Unexpected parameters: notpermitted" }
    """

  @negative @acceptance
  Scenario: Cannot create a branch with missing required parameters
    When I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "owner": { "kind": "group", "id": "data/data-group" },
      "annotations": {
        "branch2-ann-key1": "branch2-ann-val1",
        "branch2-ann-key2": "branch2-ann-val2" } }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "422",
      "message": "CONJ00190W Missing required parameter: name, branch" }
    """

  @acceptance
  Scenario: As admin I can create a branch with owner
    When I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch2", "branch": "data/safe1",
      "owner": { "kind": "group", "id": "data/data-group" },
      "annotations": { "mykey1": "abc", "mykeyffsdfs": "dfdsfsf" } }
    """
    Then the HTTP response status code is 201
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "name": "branch2", "branch": "data/safe1",
      "owner": { "kind": "group", "id": "data/data-group" },
      "annotations": { "mykey1": "abc", "mykeyffsdfs": "dfdsfsf" } }
    """

  @acceptance
  Scenario: As admin I can create a branch with admin owner
    When I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch2", "branch": "/",
      "owner": { "kind": "user", "id": "admin" },
      "annotations": { "mykey1": "abc", "mykeyffsdfs": "dfdsfsf" } }
    """
    Then the HTTP response status code is 201
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "name": "branch2", "branch": "/",
      "owner": { "kind": "user", "id": "admin" },
      "annotations": { "mykey1": "abc", "mykeyffsdfs": "dfdsfsf" } }
    """

  @negative @acceptance
  Scenario: As admin I cannot create a branch with not existing owner
    When I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch2", "branch": "data/safe1",
      "owner": { "kind": "group", "id": "data/data-group-nope" },
      "annotations": { "mykey1": "abc", "mykeyffsdfs": "dfdsfsf" } }
    """
    Then the HTTP response status code is 404
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "404",
      "message": "Group 'data/data-group-nope' not found in account 'cucumber'" }
    """

  @negative @acceptance
  Scenario: As admin I cannot create a branch with wrong name
    When I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch1<wrong>",
      "branch": "/",
      "owner": { "kind": "user", "id": "admin" } }
    """
    Then the HTTP response status code is 422
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "422",
      "message": "Name Wrong name 'branch1<wrong>'" }
    """

  @acceptance
  Scenario: A user with permission to creation in parent can create branch in it
    When I login as "alice@data-safe1"
    And I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I can POST "/branches/cucumber" with body:
    """
    { "name": "alicebranch",
      "branch": "data/safe1/branch1" }
    """
    Then the HTTP response status code is 201
    And the HTTP response content type is APIv2

  @acceptance
  Scenario: Branch with a policy as owner can be created
    When I login as "alice@data-safe1"
    And I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I can POST "/branches/cucumber" with body:
    """
    { "name": "alicebranch",
      "branch": "data/safe1/branch1",
      "owner": { "kind": "policy", "id": "data/safe1/branch1" } }
    """
    Then the HTTP response status code is 201
    And the HTTP response content type is APIv2

  @acceptance
  Scenario: A user with permission to creation in parent can create branch in it as owner
    When I login as "alice@data-safe1"
    And I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I can POST "/branches/cucumber" with body:
    """
    { "name": "alicebranch",
      "branch": "data/safe1/branch1",
       "owner": { "kind": "user", "id": "alice@data-safe1" } }
    """
    Then the HTTP response status code is 201
    And the HTTP response content type is APIv2

  @negative @acceptance
  Scenario: Cannot create branch without permission to the parent
    When I login as "alice@data-safe1"
    And I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "alicebranch",
      "branch": "data/safe1/alice-read-only" }
    """
    Then the HTTP response status code is 404
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "404",
      "message": "Branch 'data/safe1/alice-read-only' not found in account 'cucumber'" }
    """

  @negative @acceptance
  Scenario: Cannot create branch using existing name but policy is not visible
    And I am the super-user
    And I set the Accept header to APIv2
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
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "409",
      "message": "Branch \"cucumber:branch:data/safe1/branch1/alice-hidden\" already exists" }
    """

  @negative @acceptance
  Scenario: Cannot create branch using not existing user
    When I log out
    And I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch2",
      "branch": "data/safe1" }
    """
    Then the HTTP response status code is 401
#    And the HTTP response content type is APIv2
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
    And I set the Accept header to APIv2
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
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "400",
      "message": "CONJ00194W The api belongs to v2 APIs but it missing the version \"application/x.secretsmgr.v2beta+json\" in the Accept header" }
    """

  @acceptance
  Scenario: V2 header without beta is not valid
    Given I set the "Accept" header to "application/x.secretsmgr.v2+json"
    And I POST "/branches/cucumber" with body:
    """
    { "name": "branch1",
      "branch": "/",
      "owner": { "kind": "user", "id": "admin" } }
    """
    Then the HTTP response status code is 400
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "400",
      "message": "CONJ00194W The api belongs to v2 APIs but it missing the version \"application/x.secretsmgr.v2beta+json\" in the Accept header" }
    """
