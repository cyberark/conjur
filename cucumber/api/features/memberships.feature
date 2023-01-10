@api
Feature: Obtain the memberships of a role

  If a role A is granted to a role B, then role B is said to "have" role A.
  These role grants are recursive; so that if role B is granted to role C, then
  role C has roles A, B, and C (a role always "has" its own role).

  This recursive expansion of roles is called the role
  "memberships". The roles that are granted directly to a role
  (i.e. not through another role) are the role's "direct memberships".

  Memberships are retrieved through the REST API using the `all` query parameter
  to the `GET /roles/:role` route.

  If `all` is provided, all memberships are returned. If `all` is not
  provided, only the direct memberships are returned.


  Background:
    Given I am the super-user
    And I create a new user "alice"

  @smoke
  Scenario: The initial memberships of a role is just the role itself.
    When I successfully GET "/roles/cucumber/user/alice?all"
    Then the JSON should be:
    """
    [
      "cucumber:user:alice"
    ]
    """

  @smoke
  Scenario: A newly granted role is listed in the grantee's memberships.
    Given I create a new user "bob"
    And I grant user "bob" to user "alice"
    When I successfully GET "/roles/cucumber/user/alice?all"
    Then the JSON should be:
    """
    [
      "cucumber:user:alice",
      "cucumber:user:bob"
    ]
    """

  @smoke
  Scenario: Memberships can be counted
    Given I create a new user "bob"
    And I grant user "bob" to user "alice"
    When I successfully GET "/roles/cucumber/user/alice?all&count"
    Then the JSON should be:
    """
    {
      "count": 2
    }
    """

  @smoke
  Scenario: Direct memberships can be listed
    Given I create a new user "bob"
    And I create a new user "carol"
    And I grant user "carol" to user "bob"
    And I grant user "bob" to user "alice"
    Given I save my place in the audit log file for remote
    When I successfully GET "/roles/cucumber/user/alice?memberships"
    Then the JSON should be:
    """
    [
      {
        "admin_option": false,
        "member": "cucumber:user:alice",
        "ownership": false,
        "role": "cucumber:user:bob"
      }
    ]
    """
    And there is an audit record matching:
    """
      <86>1 * * conjur * membership
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" kind="user" role="cucumber:user:alice"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin successfully listed memberships with parameters: {:account=>"cucumber", :kind=>"user", :role=>"cucumber:user:alice"}
    """


  @smoke
  Scenario: Direct memberships can be counted
    Given I create a new user "bob"
    And I create a new user "carol"
    And I grant user "carol" to user "bob"
    And I grant user "bob" to user "alice"
    Given I save my place in the audit log file for remote
    When I successfully GET "/roles/cucumber/user/alice?memberships&count=true"
    Then the JSON should be:
    """
    {
      "count": 1
    }
    """
    And there is an audit record matching:
    """
      <86>1 * * conjur * membership
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" count="true" kind="user" role="cucumber:user:alice"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin successfully listed memberships with parameters: {:account=>"cucumber", :count=>"true", :kind=>"user", :role=>"cucumber:user:alice"}
    """

  @smoke
  Scenario: Direct memberships can be searched
    Given I create a new user "bob"
    And I create a new user "carol"
    And I grant user "alice" to user "bob"
    And I grant user "carol" to user "bob"
    Given I save my place in the audit log file for remote
    When I successfully GET "/roles/cucumber/user/bob?memberships&search=alice"
    Then the JSON should be:
    """
    [
      {
        "admin_option": false,
        "member": "cucumber:user:bob",
        "ownership": false,
        "role": "cucumber:user:alice"
      }
    ]
    """
    And there is an audit record matching:
    """
      <86>1 * * conjur * membership
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" search="alice" kind="user" role="cucumber:user:bob"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin successfully listed memberships with parameters: {:account=>"cucumber", :search=>"alice", :kind=>"user", :role=>"cucumber:user:bob"}
    """

  @smoke
  Scenario: The role memberships list can be filtered.

    The `filter` parameter can be used to select just a subset of the
    role memberships. This is useful for efficiently determining if a role
    has a specific other roles (or roles).

    Given I create a new user "bob"
    And I grant user "bob" to user "alice"
    Given I create a new user "charles"
    And I grant user "charles" to user "alice"
    Given I create a new user "dave"
    When I successfully GET "/roles/cucumber/user/alice" with parameters:
    """
    all: true
    filter:
    - cucumber:user:bob
    - cucumber:user:charles
    - cucumber:user:dave
    """
    Then the JSON should be:
    """
    [
      "cucumber:user:bob",
      "cucumber:user:charles"
    ]
    """

