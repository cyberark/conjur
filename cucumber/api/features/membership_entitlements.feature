Feature: Manage the role entitlements through the API

  As an affordance for users to manage the entitlements for group membership,
  there are two API endpoints for granting and revoking role membership.

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !user alice
    - !user bob
    
    - !group developers

    - !grant
      role: !group developers
      member: !user alice
    """

  Scenario: Add a group membership through the API

    When I successfully PUT "/roles/cucumber/group/developers?members&member=cucumber:user:bob"
    And I successfully GET "/roles/cucumber/group/developers"
    Then the JSON at "members" should be:
    """
    [
      {
        "admin_option": true,
        "member": "cucumber:user:admin",
        "ownership": true,
        "policy": "cucumber:policy:root",
        "role": "cucumber:group:developers"
      },
      {
        "admin_option": false,
        "member": "cucumber:user:alice",
        "ownership": false,
        "policy": "cucumber:policy:root",
        "role": "cucumber:group:developers"
      },
      {
        "admin_option": false,
        "member": "cucumber:user:bob",
        "ownership": false,
        "role": "cucumber:group:developers"
      }
    ]
    """

    Scenario: Revoke a group membership through the API

    When I successfully DELETE "/roles/cucumber/group/developers?members&member=cucumber:user:alice"
    And I successfully GET "/roles/cucumber/group/developers"
    Then the JSON at "members" should be:
    """
    [
      {
        "admin_option": true,
        "member": "cucumber:user:admin",
        "ownership": true,
        "policy": "cucumber:policy:root",
        "role": "cucumber:group:developers"
      }
    ]
    """
