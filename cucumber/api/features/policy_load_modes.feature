@api
Feature: Updating policies

  Policy updates can be performed in any of three modes: PUT, PATCH, and POST.

  * **PUT** The policy is completely replaced. Records which exist in the database but not in
  the submitted policy are deleted.
  * **PATCH** The policy is appended and updated. Records which exist in the database but not in
  the submitted policy are not deleted. Policy statements `!delete`, `!deny`, and `!revoke` can be
  used to perform destructive actions.
  * **POST** The policy is appended. No deletion is allowed.

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !user alice

    - !group everyone

    - !policy
      id: dev
      owner: !user alice
      body:
      - !policy
        id: db
    """
    And I login as "alice"
    And I successfully POST "/policies/cucumber/policy/dev/db" with body:
    """
    - !group secrets-users
    - !group secrets-managers

    - !variable a
    - !variable
      id: b
      kind: password
    """

  @smoke
  Scenario: PUT replaces the policy completely.
    Given I save my place in the audit log file for remote
    When I successfully PUT "/policies/cucumber/policy/dev/db" with body:
    """
    - !variable c
    """
    And I successfully GET "/resources/cucumber/variable"
    Then the resource list should not contain "variable" "dev/db/a"
    Then the resource list should contain "variable" "dev/db/c"
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 resource="cucumber:variable:dev/db/a"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="remove"]
      [policy@43868 id="cucumber:policy:dev/db" version="2"]
      cucumber:user:alice removed resource cucumber:variable:dev/db/a
    """

  @acceptance
  Scenario: Modifying annotations with PATCH
    Given I save my place in the audit log file for remote
    When I successfully PATCH "/policies/cucumber/policy/dev/db" with body:
    """
    - !variable
      id: b
      kind: another
    """
    When I successfully GET "/resources/cucumber/variable/dev/db/b"
    Then the JSON at "annotations" should be:
    """
    [
      {
        "name": "conjur/kind",
        "policy": "cucumber:policy:dev/db",
        "value": "another"
      }
    ]
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 annotation="conjur/kind" resource="cucumber:variable:dev/db/b"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="change"]
      [policy@43868 id="cucumber:policy:dev/db" version="2"]
      cucumber:user:alice changed annotation conjur/kind on cucumber:variable:dev/db/b
    """

  @acceptance
  Scenario: PATCH does not remove existing records
    When I successfully PATCH "/policies/cucumber/policy/dev/db" with body:
    """
    - !variable c
    """
    And I successfully GET "/resources/cucumber/variable"
    Then the resource list should contain "variable" "dev/db/a"
    Then the resource list should contain "variable" "dev/db/c"

  @acceptance
  Scenario: PATCH can explicitly delete records
    When I successfully PATCH "/policies/cucumber/policy/dev/db" with body:
    """
    - !delete
      record: !variable a
    """
    And I successfully GET "/resources/cucumber/variable"
    Then the resource list should not contain "variable" "dev/db/a"

  @acceptance
  Scenario: PATCH can perform a permission grant on existing roles and resources.
    Given I save my place in the audit log file for remote
    When I successfully PATCH "/policies/cucumber/policy/dev/db" with body:
    """
    - !permit
      role: !group /everyone
      privilege: read
      resource: !variable a
    """
    When I successfully GET "/resources/cucumber/variable/dev/db/a"
    Then the JSON at "permissions" should include:
    """
    {
      "privilege": "read",
      "role": "cucumber:group:everyone",
      "policy": "cucumber:policy:dev/db"
    }
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 resource="cucumber:variable:dev/db/a" role="cucumber:group:everyone" privilege="read"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="add"]
      [policy@43868 id="cucumber:policy:dev/db" version="2"]
      cucumber:user:alice added permission of cucumber:group:everyone to read on cucumber:variable:dev/db/a
    """

  @acceptance
  Scenario: PATCH can perform a role grant on existing roles.
    Given I save my place in the audit log file for remote
    When I successfully PATCH "/policies/cucumber/policy/dev/db" with body:
    """
    - !grant
      role: !group secrets-users
      member: !group secrets-managers
    """
    When I successfully GET "/roles/cucumber/group/dev/db/secrets-users"
    Then the JSON at "members" should include:
    """
    {
      "admin_option": false,
      "ownership": false,
      "role": "cucumber:group:dev/db/secrets-users",
      "member": "cucumber:group:dev/db/secrets-managers",
      "policy": "cucumber:policy:dev/db"
    }
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 role="cucumber:group:dev/db/secrets-users" member="cucumber:group:dev/db/secrets-managers"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="add"]
      [policy@43868 id="cucumber:policy:dev/db" version="2"]
      cucumber:user:alice added membership of cucumber:group:dev/db/secrets-managers in cucumber:group:dev/db/secrets-users
    """

  @acceptance
  Scenario: POST cannot update existing policy records
    When I successfully POST "/policies/cucumber/policy/dev/db" with body:
    """
    - !variable
      id: b
      kind: private key
    """
    When I successfully GET "/resources/cucumber/variable/dev/db/b"
    Then the JSON at "annotations" should be:
    """
    [
      {
        "name": "conjur/kind",
        "policy": "cucumber:policy:dev/db",
        "value": "password"
      }
    ]
    """

  @negative @acceptance
  Scenario: POST cannot remove existing records
    When I POST "/policies/cucumber/policy/dev/db" with body:
    """
    - !delete
      record: !variable a
    """
    Then the HTTP response status code is 422
    And the JSON response should be:
    """
    {
      "error": {
        "code": "validation_failed",
        "details": [
          {
            "code": "validation_failed",
            "message": "may not contain deletion statements",
            "target": "policy_text"
          }
        ],
        "message": "policy_text may not contain deletion statements"
      }
    }
    """
