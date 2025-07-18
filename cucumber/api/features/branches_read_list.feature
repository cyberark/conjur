@api
Feature: Branches APIv2 tests - read list

  Background:
    Given I am the super-user
    And I can POST "/policies/cucumber/policy/root" with body from file "policy_data.yml"

  @acceptance
  Scenario: As admin I can list branches from root
    Given I set the Accept header to APIv2
    And I save my place in the audit log file for remote
    When I can GET "/branches/cucumber"
    Then the HTTP response status code is 200
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "branches": [
      { "name": "data",
       "branch": "/",
       "owner": { "kind": "group", "id": "Conjur_Admins" },
       "annotations": {} },
      { "name": "Applications",
       "branch": "data",
       "owner": { "kind": "policy", "id": "data" },
       "annotations": {} },
      { "name": "App-A",
       "branch": "data/Applications",
       "owner": { "kind": "policy", "id": "data/Applications" },
       "annotations": {} },
      { "name": "data_default_owner",
       "branch": "/",
       "owner": { "kind": "user", "id": "admin" },
       "annotations": {} },
      { "name": "dynamic",
       "branch": "data",
       "owner": { "kind": "group", "id": "Conjur_Issuers_Admins" },
       "annotations": {} },
      { "name": "safe1",
       "branch": "data",
       "owner": { "kind": "policy", "id": "data" },
       "annotations": {} },
      { "name": "alice-execute-only",
       "branch": "data/safe1",
       "owner": { "kind": "policy", "id": "data/safe1" },
       "annotations": {} },
      { "name": "alice-read-only",
       "branch": "data/safe1",
       "owner": { "kind": "policy", "id": "data/safe1" },
       "annotations": {} },
      { "name": "branch1",
       "branch": "data/safe1",
       "owner": { "kind": "group", "id": "data/data-group" },
       "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "123" } },
      { "name": "alice-branch",
       "branch": "data/safe1/branch1",
       "owner": { "kind": "user", "id": "alice@data-safe1" },
       "annotations": { "alice-ann-1": "Alice notes 1", "alice-ann-2": "Alice notes 2" } },
      { "name": "vault",
       "branch": "data",
       "owner": { "kind": "group", "id": "data/vault-admins" },
       "annotations": {} },
      { "name": "some_branch",
        "branch": "/",
        "owner": { "id": "bob", "kind": "user" },
        "annotations": {} },
      { "name": "branch_own_owner",
        "branch": "some_branch",
        "owner": { "id": "some_branch/branch_own_owner", "kind": "policy" },
        "annotations": {} } ],
      "count": 13 }
    """
    And there is an audit record matching:
    """
    <85>1 * * conjur * branch\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="success" operation="list"]\s
    cucumber:user:admin successfully listed branch root with URI path: '/branches/cucumber'
    """

  @acceptance
  Scenario: As not admin I can list branches from root that are visible for me
    Given I login as "alice@data-safe1"
    And I set the Accept header to APIv2
    When I can GET "/branches/cucumber"
    Then the HTTP response status code is 200
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "branches": [
      { "name": "alice-read-only",
        "branch": "data/safe1",
        "owner": { "kind": "policy", "id": "data/safe1" },
        "annotations": {} },
      { "name": "branch1",
        "branch": "data/safe1",
        "owner": { "kind": "group", "id": "data/data-group" },
        "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "123" } },
      { "name": "alice-branch",
        "branch": "data/safe1/branch1",
        "owner": { "kind": "user", "id": "alice@data-safe1" },
        "annotations": { "alice-ann-1": "Alice notes 1", "alice-ann-2": "Alice notes 2" } } ],
      "count": 3 }
    """

  @acceptance
  Scenario: As admin I can list branches from root using pagination
    Given I set the Accept header to APIv2
    When I can GET "/branches/cucumber?offset=2;limit=3"
    Then the HTTP response status code is 200
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "branches": [
      { "name": "App-A",
        "branch": "data/Applications",
        "owner": { "kind": "policy", "id": "data/Applications" },
        "annotations": {} },
      { "name": "data_default_owner",
        "branch": "/",
        "owner": { "kind": "user", "id": "admin" },
        "annotations": {} },
      { "name": "dynamic",
        "branch": "data",
        "owner": { "kind": "group", "id": "Conjur_Issuers_Admins" },
        "annotations": {} } ],
      "count": 13 }
    """

  @negative @acceptance
  Scenario: Error due to wrong pagination parameters
    Given I set the Accept header to APIv2
    And I save my place in the audit log file for remote
    And I save my place in the audit log file for remote
    When I GET "/branches/cucumber?offset=2;limit=-1"
    Then the HTTP response status code is 422
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "422",
      "message": "Limit must be greater than or equal to 0" }
    """
    And there is an audit record matching:
    """
    <85>1 * * conjur * branch\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="failure" operation="list"]\s
    cucumber:user:admin failed to list branch root with URI path: '/branches/cucumber': Limit must be greater than or equal to 0
    """

  @acceptance
  Scenario: Cannot list branches with not existing parent branch
    Given I am the super-user
    And I clear the "Accept" header
    And I clear the "Content-Type" header
    And I can PATCH "/policies/cucumber/policy/data/safe1/branch1" with body:
    """
    ---
    - !policy not_for_branch/branch2
    """
    And I set the Accept header to APIv2
    When I can GET "/branches/cucumber"
    Then the HTTP response status code is 200
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "branches": [
      { "name": "data",
        "branch": "/",
        "owner": { "kind": "group", "id": "Conjur_Admins" },
        "annotations": {} },
      { "name": "Applications",
        "branch": "data",
        "owner": { "kind": "policy", "id": "data" },
        "annotations": {} },
      { "name": "App-A",
        "branch": "data/Applications",
        "owner": { "kind": "policy", "id": "data/Applications" },
        "annotations": {} },
      { "name": "data_default_owner",
        "branch": "/",
        "owner": { "kind": "user", "id": "admin" },
        "annotations": {} },
      { "name": "dynamic",
        "branch": "data", "owner": { "kind": "group", "id": "Conjur_Issuers_Admins" },
        "annotations": {} },
      { "name": "safe1",
        "branch": "data",
        "owner": { "kind": "policy", "id": "data" },
        "annotations": {} },
      { "name": "alice-execute-only",
        "branch": "data/safe1",
        "owner": { "kind": "policy", "id": "data/safe1" },
        "annotations": {} },
      { "name": "alice-read-only",
        "branch": "data/safe1",
        "owner": { "kind": "policy", "id": "data/safe1" },
        "annotations": {} },
      { "name": "branch1",
        "branch": "data/safe1",
        "owner": { "kind": "group", "id": "data/data-group" },
        "annotations": { "branch1-ann-1": "Foo bar", "branch1-ann-2": "123" } },
      { "name": "alice-branch",
        "branch": "data/safe1/branch1",
        "owner": { "kind": "user", "id": "alice@data-safe1" },
        "annotations": { "alice-ann-1": "Alice notes 1", "alice-ann-2": "Alice notes 2" } },
      { "name": "vault",
        "branch": "data",
        "owner": { "kind": "group", "id": "data/vault-admins" },
        "annotations": {} },
      { "name": "some_branch",
        "branch": "/",
        "owner": { "id": "bob", "kind": "user" },
        "annotations": {} },
      { "name": "branch_own_owner",
        "branch": "some_branch",
        "owner": { "id": "some_branch/branch_own_owner", "kind": "policy" },
        "annotations": {} } ],
      "count": 13 }
    """

  @acceptance
  Scenario: V2 header must be present
    Given I clear the "Accept" header
    When I GET "/branches/cucumber"
    Then the HTTP response status code is 400
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "400",
      "message": "CONJ00194W The api belongs to v2 APIs but it missing the version \"application/x.secretsmgr.v2beta+json\" in the Accept header" }
    """
