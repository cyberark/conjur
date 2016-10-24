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
    And I successfully PUT "/policies/:account/policy/bootstrap" with body:
    """
    - !policy
      id: @namespace@
      body:
      - !user alice

      - !policy
        id: dev
        owner: !user alice
        body:
        - !policy
          id: db
    """
    And I login as "alice"
    And I successfully POST "/policies/:account/policy/:namespace/dev/db" with body:
    """
    - !variable a
    - !variable
      id: b
      kind: password
    """

  Scenario: PUT replaces the policy completely.
    When I successfully PUT "/policies/:account/policy/:namespace/dev/db" with body:
    """
    - !variable c
    """
    And I successfully GET "/resources/:account/variable"
    Then the resource list should not contain "variable" "dev/db/a"
    Then the resource list should contain "variable" "dev/db/c"

  Scenario: PATCH does not remove existing records
    When I successfully PATCH "/policies/:account/policy/:namespace/dev/db" with body:
    """
    - !variable c
    """
    And I successfully GET "/resources/:account/variable"
    Then the resource list should contain "variable" "dev/db/a"
    Then the resource list should contain "variable" "dev/db/c"

  Scenario: PATCH can explicitly delete records
    When I successfully PUT "/policies/:account/policy/:namespace/dev/db" with body:
    """
    - !delete
      record: !variable a
    - !variable c
    """
    And I successfully GET "/resources/:account/variable"
    Then the resource list should not contain "variable" "dev/db/a"
    Then the resource list should contain "variable" "dev/db/c"

  Scenario: POST cannot update existing policy records
    When I successfully POST "/policies/:account/policy/:namespace/dev/db" with body:
    """
    - !variable
      id: b
      kind: private key
    """
    When I successfully GET "/resources/:account/variable/:namespace/dev/db/b"
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

  Scenario: POST cannot remove existing records
    When I POST "/policies/:account/policy/:namespace/dev/db" with body:
    """
    - !delete
      record: !variable a
    """
    Then it's unprocessable
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
