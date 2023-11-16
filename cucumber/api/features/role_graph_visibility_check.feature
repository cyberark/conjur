@api
Feature: The role graph for a given role render appropriately, showing only
  the edges of the graph where the current user has read permissions
  on both the parent and child.

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !user testuser
    - !user testuser2
    - !user testuser3

    - !group
        id: test-admins

    - !policy
        id: test-policy
        owner: !group test-admins

    - !grant
        role: !group test-admins
        members:
            - !user testuser

    - !permit
        role: !user testuser3
        privilege: read
        resources: !group test-admins
    """

  @smoke
  Scenario: Retrieving as admin returns the entire graph
    Given I login as "admin"
    When I successfully GET "roles/cucumber/policy/test-policy?graph"
    Then the JSON should be:
      """
      [
        {
          "parent": "cucumber:group:test-admins",
          "child": "cucumber:user:admin"
        },
        {
          "parent": "cucumber:group:test-admins",
          "child": "cucumber:user:testuser"
        },
        {
          "parent": "cucumber:policy:test-policy",
          "child": "cucumber:group:test-admins"
        },
        {
          "parent": "cucumber:user:testuser",
          "child": "cucumber:user:admin"
        }
      ]
      """

  @smoke
  Scenario: Retrieving graph shows only the edges policy owner has read permissions for
    Given I login as "testuser"
    When I successfully GET "/roles/cucumber/policy/test-policy?graph"
    Then the JSON should be:
      """
      [
        {
          "parent": "cucumber:policy:test-policy",
          "child": "cucumber:group:test-admins"
        }
      ]
      """

  Scenario: Retrieving graph that user has no permissions for returns 404
    Given I login as "testuser2"
    When I GET "/roles/cucumber/policy/test-policy?graph"
    Then the HTTP response status code is 404

  Scenario: Retrieving graph shows only the edges user has read permissions for
    # Read permissions for a group allow user to see members of the group
    Given I login as "testuser3"
    When I GET "/roles/cucumber/policy/test-policy?graph"
    Then the HTTP response status code is 404
    And I successfully GET "/roles/cucumber/group/test-admins?graph"
    Then the JSON should be:
      """
      [
        {
          "parent": "cucumber:group:test-admins",
          "child": "cucumber:user:admin"
        },
        {
          "parent": "cucumber:group:test-admins",
          "child": "cucumber:user:testuser"
        }
      ]
      """
