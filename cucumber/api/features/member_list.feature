@api
Feature: List and filter members of a role

The members of a role can be listed, searched, and paged.

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - &users
      - !user alice
      - !user bob
      - !user charlotte
      - !user alicia

    - !group dev
    - !group employees

    - !grant
      role: !group dev
      members: *users

    - !grant
      role: !group employees
      member: !group dev

    - !grant
      role: !group employees
      members: !user alice
    """

  @smoke
  Scenario: List role members
    When I successfully GET "/roles/cucumber/group/dev?members"
    Then the JSON should be:
        """
        [
        {
            "admin_option": true,
            "member": "cucumber:user:admin",
            "ownership": true,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:dev"
        },
        {
            "admin_option": false,
            "member": "cucumber:user:alice",
            "ownership": false,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:dev"
        },
        {
            "admin_option": false,
            "member": "cucumber:user:alicia",
            "ownership": false,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:dev"
        },
        {
            "admin_option": false,
            "member": "cucumber:user:bob",
            "ownership": false,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:dev"
        },
        {
            "admin_option": false,
            "member": "cucumber:user:charlotte",
            "ownership": false,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:dev"
        }
        ]
        """

  @smoke
  Scenario: Search role members
    When I successfully GET "/roles/cucumber/group/dev?members&search=alice"
    Then the JSON should be:
        """
        [
        {
            "admin_option": false,
            "member": "cucumber:user:alice",
            "ownership": false,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:dev"
        }
        ]
        """

  @acceptance
  Scenario: Search for non-existant member
     When I successfully GET "/roles/cucumber/group/dev?members&search=non_existent_user"
     Then the JSON should be:
         """
         []
         """

  @smoke
  Scenario: Page role members
    When I successfully GET "/roles/cucumber/group/dev?members&limit=3"
    Then the JSON should be:
        """
        [
        {
            "admin_option": true,
            "member": "cucumber:user:admin",
            "ownership": true,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:dev"
        },
        {
            "admin_option": false,
            "member": "cucumber:user:alice",
            "ownership": false,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:dev"
        },
        {
            "admin_option": false,
            "member": "cucumber:user:alicia",
            "ownership": false,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:dev"
        }
        ]
        """

    When I successfully GET "/roles/cucumber/group/dev?members&limit=3&offset=3"
    Then the JSON should be:
        """
        [
        {
            "admin_option": false,
            "member": "cucumber:user:bob",
            "ownership": false,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:dev"
        },
        {
            "admin_option": false,
            "member": "cucumber:user:charlotte",
            "ownership": false,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:dev"
        }
        ]
        """

  @smoke
  Scenario: Counting role members
    When I successfully GET "/roles/cucumber/group/dev?members&count=true"
    Then the JSON should be:
    """
    {
        "count": 5
    }
    """

    When I successfully GET "/roles/cucumber/group/dev?members&count=true&limit=3"
    Then the JSON should be:
    """
    {
        "count": 5
    }
    """

  @smoke
  Scenario: Filter role members by kind
    When I successfully GET "/roles/cucumber/group/employees?members&kind[]=group&kind[]=user"
    Then the JSON should be:
    """
    [
        {
            "admin_option": false,
            "member": "cucumber:group:dev",
            "ownership": false,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:employees"
        },
        {
          "admin_option": true,
          "member": "cucumber:user:admin",
          "ownership": true,
          "policy": "cucumber:policy:root",
          "role": "cucumber:group:employees"
        },
        {
            "admin_option": false,
            "member": "cucumber:user:alice",
            "ownership": false,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:employees"
        }
    ]
    """

    When I successfully GET "/roles/cucumber/group/employees?members&kind[]=group"
    Then the JSON should be:
    """
    [
        {
            "admin_option": false,
            "member": "cucumber:group:dev",
            "ownership": false,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:employees"
        }
    ]
    """

    When I successfully GET "/roles/cucumber/group/employees?members&kind=group"
    Then the JSON should be:
    """
    [
        {
            "admin_option": false,
            "member": "cucumber:group:dev",
            "ownership": false,
            "policy": "cucumber:policy:root",
            "role": "cucumber:group:employees"
        }
    ]
    """
