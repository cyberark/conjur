@api
Feature: Group Memberships APIv2 tests - create

  Background:
    Given I am the super-user
    And I can POST "/policies/cucumber/policy/root" with body from file "policy_data.yml"
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I save my place in the audit log file for remote
    When I can POST "/groups/cucumber/data/data-group/members" with body:
    """
    { "kind": "host",
      "id": "data/myhost" }
    """
    And the HTTP response status code is 201
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

  @acceptance
  Scenario: As admin I can remove a member from a group
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I can DELETE "/groups/cucumber/data/data-group/members/host/data/myhost"
    And the HTTP response status code is 204
    Then there is an audit record matching:
    """
    <85>1 * * conjur * membership\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="success" operation="remove"]\s
    cucumber:user:admin successfully removed membership data/data-group with URI path: '/groups/cucumber/data/data-group/members/host/data/myhost'
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
    """


  @negative @acceptance
  Scenario: Cannot remove a member from a group that is not a member
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I DELETE "/groups/cucumber/data/data-group/members/host/data/myhost-nope"
    And the HTTP response status code is 422
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "422",
      "message": "Host 'data/myhost-nope' not found in account 'cucumber'" }
    """
    Then there is an audit record matching:
    """
    <85>1 * * conjur * membership\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="failure" operation="remove"]\s
    cucumber:user:admin failed to remove membership data/data-group with URI path: '/groups/cucumber/data/data-group/members/host/data/myhost-nope': Host 'data/myhost-nope' not found in account 'cucumber'
    """

  @negative @acceptance
  Scenario: Cannot remove a member from a not existing group
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I DELETE "/groups/cucumber/data/data-group-nope/members/host/data/myhost"
    And the HTTP response status code is 404
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "404",
      "message": "Group 'data/data-group-nope' not found in account 'cucumber'" }
    """
    Then there is an audit record matching:
    """
    <85>1 * * conjur * membership\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="failure" operation="remove"]\s
    cucumber:user:admin failed to remove membership data/data-group-nope with URI path: '/groups/cucumber/data/data-group-nope/members/host/data/myhost': Group 'data/data-group-nope' not found in account 'cucumber'
    """

  @negative @acceptance
  Scenario: Cannot remove a member from a not existing group
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I DELETE "/groups/cucumber/data/data-group-nope/members/host/data/myhost"
    And the HTTP response status code is 404
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "404",
      "message": "Group 'data/data-group-nope' not found in account 'cucumber'" }
    """
    Then there is an audit record matching:
    """
    <85>1 * * conjur * membership\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="failure" operation="remove"]\s
    cucumber:user:admin failed to remove membership data/data-group-nope with URI path: '/groups/cucumber/data/data-group-nope/members/host/data/myhost': Group 'data/data-group-nope' not found in account 'cucumber'
    """

  @negative @acceptance
  Scenario: Cannot remove a member without permission
    When I login as "alice@data-safe1"
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I DELETE "/groups/cucumber/data/data-group/members/host/data/myhost"
    And the HTTP response status code is 404
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "404",
      "message": "Branch 'data' not found in account 'cucumber'" }
    """
    Then there is an audit record matching:
    """
    <85>1 * * conjur * membership\s
    [auth@43868 user="cucumber:user:alice@data-safe1"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="failure" operation="remove"]\s
    cucumber:user:alice@data-safe1 failed to remove membership data/data-group with URI path: '/groups/cucumber/data/data-group/members/host/data/myhost': Branch 'data' not found in account 'cucumber'
    """

  @acceptance
  Scenario: Can remove a member from root
    Given I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I DELETE "/groups/cucumber/Conjur_Issuers_Admins/members/group/Conjur_Admins"
    And the HTTP response status code is 204
    Then there is an audit record matching:
    """
    <85>1 * * conjur * membership\s
    [auth@43868 user="cucumber:user:admin"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="success" operation="remove"]\s
    cucumber:user:admin successfully removed membership Conjur_Issuers_Admins with URI path: '/groups/cucumber/Conjur_Issuers_Admins/members/group/Conjur_Admins'
    """
