@api
Feature: List direct members of a role

  If a role A is granted to a role B, then role A is said to have role B as a 
  member.

  Unlike role memberships, role members are not expanded recursively.

  Background:
    Given I create a new user "bob"
    And I am a user named "alice"

  @smoke
  Scenario: Initial roles members is just the initial role admin.

    At the time a new role ("alice") is created, the role is granted
    with admin option to the "creating" role ("admin"). Thus the initial
    members of role "alice" is the set containing only role "admin".  

    When I successfully GET "/roles/cucumber/user/alice"
    Then the JSON at "members" should be:
    """
    [
      {
        "admin_option": true,
        "member": "cucumber:user:admin",
        "ownership": true,
        "role": "cucumber:user:alice"
      }
    ]
    """

  @smoke
  Scenario: New member roles appear in the role list.

    Granting a role ("alice") to a new role ("bob") results in 
    "bob" appearing in the set of members of "alice".

    Given I grant user "alice" to user "bob"
    When I successfully GET "/roles/cucumber/user/alice"
    Then the JSON at "members" should be:
    """
    [
      {
        "admin_option": true,
        "member": "cucumber:user:admin",
        "ownership": true,
        "role": "cucumber:user:alice"
      },
      {
        "admin_option": false,
        "member": "cucumber:user:bob",
        "ownership": false,
        "role": "cucumber:user:alice"
      }
    ]
    """
