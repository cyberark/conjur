@api
Feature: Policy loading error messages

  @negative @acceptance
  @logged-in-admin
  Scenario: A policy which references a non-existing resource reports the error.

    The error message provides the id of the record that was not found.
    Given I save my place in the audit log file for remote
    When I POST "/policies/cucumber/policy/root" with body:
    """
    - !variable password

    - !permit
      role: !user bob
      privilege: [ execute ]
      resource: !variable password
    """
    Then the HTTP response status code is 404
    And the JSON response should be:
    """
    {
      "error": {
        "code": "not_found",
        "message": "User 'bob' not found in account 'cucumber'",
        "target": "user",
        "details": {
          "code": "not_found",
          "target": "id",
          "message": "cucumber:user:bob"
        }
      }
    }
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="create"]
      Failed to load policy: User 'bob' not found in account 'cucumber'
    """

  @negative @acceptance
  @logged-in-admin
  Scenario: A policy with a blank resource id reports the error.
    Given I save my place in the audit log file for remote
    When I POST "/policies/cucumber/policy/root" with body:
    """
    - !user bob

    - !permit
      role: !user bob
      privilege: [ execute ]
      resource:
    """
    Then the HTTP response status code is 422
    And the JSON response should be:
    """
    {
      "error": {
        "code": "validation_failed",
        "message": "policy_text resource has a blank id",
        "details": [
          {
            "code": "validation_failed",
            "target": "policy_text",
            "message": "resource has a blank id"
          }
        ]
      }
    }
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="create"]
      Failed to load policy: policy_text resource has a blank id
    """

  @negative @acceptance
  @logged-in-admin
  Scenario: Posting a policy without a body
    Given I save my place in the audit log file for remote
    When I POST "/policies/cucumber/policy/root"
    Then the HTTP response status code is 422
    And the JSON response should be:
    """
    {
      "error": {
        "code": "validation_failed",
        "message": "policy_text is not present",
        "details": [
          {
            "code": "validation_failed",
            "target": "policy_text",
            "message": "is not present"
          }
        ]
      }
    }
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="create"]
      Failed to load policy: policy_text is not present
    """
