@logged-in
Feature: List resources for another role
  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !user alice
    - !user bob
    - !policy
      id: dev
      owner: !user alice
      body:
        - !variable dev-var
    - !policy
      id: prod
      owner: !user bob
      body:
        - !variable prod-var
    """

  Scenario: The resource list can be retrieved for a different role, specified the query parameter role
    When I successfully GET "/resources?role=cucumber:user:alice"
    Then the resource list should contain "variable" "dev/dev-var"
    And the resource list should not contain "variable" "prod/prod-var"

  Scenario: The resource list can be retrieved for a different role, specified the query parameter acting_as
    When I successfully GET "/resources?acting_as=cucumber:user:alice"
    Then the resource list should contain "variable" "dev/dev-var"
    And the resource list should not contain "variable" "prod/prod-var"
