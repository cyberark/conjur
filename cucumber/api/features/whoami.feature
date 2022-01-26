@api
Feature: Who Am I

  @acceptance
  Scenario: Audit entry

    Given I am a user named "alice"
    And I save my place in the audit log file for remote
    When I successfully GET "/whoami"
    Then there is an audit record matching:
    """
      <38>1 * * conjur * identity-check
      [subject@43868 role="cucumber:user:alice"]
      [auth@43868 user="cucumber:user:alice"]
      [client@43868 ip="*"]
      [action@43868 result="success" operation="check"]
      * *
      cucumber:user:alice checked its identity using whoami
    """
