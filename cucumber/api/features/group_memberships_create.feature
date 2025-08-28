@api
Feature: Group Memberships APIv2 tests - create

  Background:
    Given I am the super-user
    And I can POST "/policies/cucumber/policy/root" with body from file "policy_data.yml"

  @acceptance
  Scenario: As admin I can add a member to a group
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I save my place in the audit log file for remote
    When I can POST "/groups/cucumber/data/data-group/members" with body:
    """
    { "kind": "host",
      "id": "data/myhost" }
    """
    And the HTTP response status code is 201
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "kind": "host",
      "id": "data/myhost" }
    """
    Then there is an audit record matching:
    """
    <85>1 * * conjur * membership\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="success" operation="create"]\s
    cucumber:user:admin successfully created membership data/data-group with URI path: '/groups/cucumber/data/data-group/members' and JSON object: {"kind":"host","id":"data/myhost"}
    """
    And I clear the "Accept" header
    And I clear the "Content-Type" header
    And I can GET "/policies/cucumber/policy/data?depth=1"
    Then the yaml result is:
    """
    ---
    - !policy
      id: data
      owner: !group /Conjur_Admins
      body:
      - !policy
        id: Applications
        body: []
      - !policy
        id: dynamic
        owner: !group /Conjur_Issuers_Admins
        body: []
      - !policy
        id: safe1
        body:
        - !user alice
      - !policy
        id: vault
        owner: !group /data/vault-admins
        body: []
      - !host myhost
      - !group data-group
      - !group vault-admins
      - !grant
        role: !group data-group
        members:
        - !host /data/myhost
    """

  @negative @acceptance
  Scenario: Cannot add a member to a group that does not exist
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I save my place in the audit log file for remote
    When I POST "/groups/cucumber/data/data-group-non/members" with body:
    """
    { "kind": "host",
      "id": "data/myhost" }
    """
    And the HTTP response status code is 404
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "404",
      "message": "Group 'data/data-group-non' not found in account 'cucumber'" }
    """
    Then there is an audit record matching:
    """
    <85>1 * * conjur * membership\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="failure" operation="create"]\s
    cucumber:user:admin failed to create membership data/data-group-non with URI path: '/groups/cucumber/data/data-group-non/members' and JSON object: {"kind":"host","id":"data/myhost"}: Group 'data/data-group-non' not found in account 'cucumber'
    """

  @negative @acceptance
  Scenario: Body JSON not well formed
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I save my place in the audit log file for remote
    When I POST "/groups/cucumber/data/data-group-non/members" with body:
    """
    "kind": "host",
    "id": "data/myhost"
    """
    And the HTTP response status code is 400
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "400",
    "message": "Invalid JSON body: unexpected token at ': \"host\",\n\"id\": \"data/myhost\"'" }
    """
    Then there is an audit record matching:
    """
    <85>1 * * conjur * membership\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="failure" operation="create"]\s
    cucumber:user:admin failed to create membership data/data-group-non with URI path: '/groups/cucumber/data/data-group-non/members' and JSON object: "kind": "host", "id": "data/myhost": Invalid JSON body: unexpected token at ': "host", "id": "data/myhost"'
    """
