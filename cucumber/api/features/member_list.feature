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
    Given I save my place in the audit log file for remote
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
    And there is an audit record matching:
    """
      <86>1 * * conjur * members
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" kind="group" role="cucumber:group:dev"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin successfully listed members with parameters: {:account=>"cucumber", :kind=>"group", :role=>"cucumber:group:dev"}
    """

  @smoke
  Scenario: Search role members
    Given I save my place in the audit log file for remote
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
    And there is an audit record matching:
    """
      <86>1 * * conjur * members
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" kind="group" search="alice" role="cucumber:group:dev"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin successfully listed members with parameters: {:account=>"cucumber", :kind=>"group", :search=>"alice", :role=>"cucumber:group:dev"}
    """


  @acceptance
  Scenario: Search for non-existant member
    Given I save my place in the audit log file for remote
     When I successfully GET "/roles/cucumber/group/dev?members&search=non_existent_user"
     Then the JSON should be:
         """
         []
         """
    And there is an audit record matching:
    """
      <86>1 * * conjur * members
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" kind="group" search="non_existent_user" role="cucumber:group:dev"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin successfully listed members with parameters: {:account=>"cucumber", :kind=>"group", :search=>"non_existent_user", :role=>"cucumber:group:dev"}
    """


  @smoke
  Scenario: Page role members
    Given I save my place in the audit log file for remote
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
    And there is an audit record matching:
    """
      <86>1 * * conjur * members
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" kind="group" limit="3" role="cucumber:group:dev"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin successfully listed members with parameters: {:account=>"cucumber", :kind=>"group", :limit=>"3", :role=>"cucumber:group:dev"}
    """

    Given I save my place in the audit log file for remote
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
    And there is an audit record matching:
    """
      <86>1 * * conjur * members
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" kind="group" limit="3" offset="3" role="cucumber:group:dev"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin successfully listed members with parameters: {:account=>"cucumber", :kind=>"group", :limit=>"3", :offset=>"3", :role=>"cucumber:group:dev"}
    """

  @smoke
  Scenario: Counting role members
    Given I save my place in the audit log file for remote
    When I successfully GET "/roles/cucumber/group/dev?members&count=true"
    Then the JSON should be:
    """
    {
        "count": 5
    }
    """
    And there is an audit record matching:
    """
      <86>1 * * conjur * members
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" count="true" kind="group" role="cucumber:group:dev"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin successfully listed members with parameters: {:account=>"cucumber", :count=>"true", :kind=>"group", :role=>"cucumber:group:dev"}
    """

    Given I save my place in the audit log file for remote
    When I successfully GET "/roles/cucumber/group/dev?members&count=true&limit=3"
    Then the JSON should be:
    """
    {
        "count": 5
    }
    """
    And there is an audit record matching:
    """
      <86>1 * * conjur * members
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" count="true" kind="group" limit="3" role="cucumber:group:dev"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin successfully listed members with parameters: {:account=>"cucumber", :count=>"true", :kind=>"group", :limit=>"3", :role=>"cucumber:group:dev"}
    """

  @smoke
  Scenario: Filter role members by kind
    Given I save my place in the audit log file for remote
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
    And there is an audit record matching:
    """
      <86>1 * * conjur * members
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" kind="group" role="cucumber:group:employees"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin successfully listed members with parameters: {:account=>"cucumber", :kind=>"group", :role=>"cucumber:group:employees"}
    """

    Given I save my place in the audit log file for remote
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
    And there is an audit record matching:
    """
      <86>1 * * conjur * members
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" kind="group" role="cucumber:group:employees"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin successfully listed members with parameters: {:account=>"cucumber", :kind=>"group", :role=>"cucumber:group:employees"}
    """

    Given I save my place in the audit log file for remote
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
    And there is an audit record matching:
    """
      <86>1 * * conjur * members
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" kind="group" role="cucumber:group:employees"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin successfully listed members with parameters: {:account=>"cucumber", :kind=>"group", :role=>"cucumber:group:employees"}
    """


  @negative @acceptance
  Scenario: The members list cannot be limited with non numeric value
    Given I save my place in the audit log file for remote
    When I GET "/roles/cucumber/group/dev?members&limit=abc"
    Then the HTTP response status code is 500
    And there is an audit record matching:
    """
      <84>1 * * conjur * members
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" kind="group" limit="abc" role="cucumber:group:dev"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="list"]
      cucumber:user:admin failed to list members with parameters: {:account=>"cucumber", :kind=>"group", :limit=>"abc", :role=>"cucumber:group:dev"}:
      Limits must be greater than or equal to 1
    """

