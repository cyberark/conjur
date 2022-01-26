@api
Feature: Retrieve the role graph for a given role

  The full graph of ancestor and descendent roles for a given
  role can be retrieved throug the api

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """

    - !group internal
    - !layer applications
    - !group shipping
    - !user alice

    - !grant
      role: !group internal
      member: !layer applications

    - !grant
      role: !layer applications
      member: !group shipping

    - !grant
      role: !group shipping
      member: !user alice
    """

  @smoke
  Scenario: Retrieve role graph
    When I successfully GET "/roles/cucumber/group/internal?graph"
    Then the JSON should be:
        """
        [
          {
            "parent": "cucumber:group:internal",
            "child": "cucumber:layer:applications"
          },
          {
            "parent": "cucumber:group:internal",
            "child": "cucumber:user:admin"
          },
          {
            "parent": "cucumber:group:shipping",
            "child": "cucumber:user:admin"
          },
          {
            "parent": "cucumber:group:shipping",
            "child": "cucumber:user:alice"
          },
          {
            "parent": "cucumber:layer:applications",
            "child": "cucumber:group:shipping"
          },
          {
            "parent": "cucumber:layer:applications",
            "child": "cucumber:user:admin"
          },
          {
            "parent": "cucumber:user:alice",
            "child": "cucumber:user:admin"
          }
        ]
        """