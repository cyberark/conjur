@api
Feature: Manage the role entitlements through the API

  As an affordance for users to manage the entitlements for group membership,
  there are two API endpoints for granting and revoking role membership.

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !user alice
    - !user bob

    - !policy
      id: dev
      body:
      - !group developers

    - !grant
      role: !group dev/developers
      member: !user alice

    - !permit
      resource: !policy root
      privileges: [ create, update ]
      roles: !user alice
    """

  @smoke
  Scenario: Add a group membership through the API
    Given I save my place in the audit log file for remote
    When I successfully POST "/roles/cucumber/group/dev%2Fdevelopers?members&member=cucumber:user:bob"
    And I successfully GET "/roles/cucumber/group/dev%2Fdevelopers"
    Then the JSON at "members" should be:
    """
    [
      {
        "admin_option": true,
        "member": "cucumber:policy:dev",
        "ownership": true,
        "policy": "cucumber:policy:root",
        "role": "cucumber:group:dev/developers"
      },
      {
        "admin_option": false,
        "member": "cucumber:user:alice",
        "ownership": false,
        "policy": "cucumber:policy:root",
        "role": "cucumber:group:dev/developers"
      },
      {
        "admin_option": false,
        "member": "cucumber:user:bob",
        "ownership": false,
        "role": "cucumber:group:dev/developers"
      }
    ]
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 role="cucumber:group:dev/developers" member="cucumber:user:bob"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="add"]
      cucumber:user:admin added membership of cucumber:user:bob in cucumber:group:dev/developers
    """

  @smoke
  Scenario: Revoke a group membership through the API

    Given I login as "alice"
    And I save my place in the audit log file for remote
    When I successfully DELETE "/roles/cucumber/group/dev%2Fdevelopers?members&member=cucumber:user:alice"
    And I successfully GET "/roles/cucumber/group/dev%2Fdevelopers"
    Then the JSON at "members" should be:
    """
    [
      {
        "admin_option": true,
        "member": "cucumber:policy:dev",
        "ownership": true,
        "policy": "cucumber:policy:root",
        "role": "cucumber:group:dev/developers"
      }
    ]
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy [auth@43868 user="cucumber:user:alice"]
      [subject@43868 role="cucumber:group:dev/developers" member="cucumber:user:alice"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="remove"]
      cucumber:user:alice removed membership of cucumber:user:alice in cucumber:group:dev/developers
    """

  @negative @acceptance
  Scenario: Add a membership without permissions

    Given I login as "bob"
    When I POST "/roles/cucumber/group/dev%2Fdevelopers?members&member=cucumber:user:bob"
    Then the HTTP response status code is 403

  @acceptance
  Scenario: Attempt to add a member twice

    When I successfully POST "/roles/cucumber/group/dev%2Fdevelopers?members&member=cucumber:user:bob"
    And I successfully POST "/roles/cucumber/group/dev%2Fdevelopers?members&member=cucumber:user:bob"
    And I successfully GET "/roles/cucumber/group/dev%2Fdevelopers"
    Then the JSON at "members" should be:
    """
    [
      {
        "admin_option": true,
        "member": "cucumber:policy:dev",
        "ownership": true,
        "policy": "cucumber:policy:root",
        "role": "cucumber:group:dev/developers"
      },
      {
        "admin_option": false,
        "member": "cucumber:user:alice",
        "ownership": false,
        "policy": "cucumber:policy:root",
        "role": "cucumber:group:dev/developers"
      },
      {
        "admin_option": false,
        "member": "cucumber:user:bob",
        "ownership": false,
        "role": "cucumber:group:dev/developers"
      }
    ]
    """
