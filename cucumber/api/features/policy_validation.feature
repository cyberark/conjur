@api
Feature: Updating policies


  @smoke
  Scenario: When a policy is validated it is audited and not loaded.
    Given I am the super-user
    And I save my place in the audit log file for remote
    And I successfully POST "/policies/cucumber/policy/root?validate=true" with body:
    """
    - !user alice
    """
    Then there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="validate"]
      cucumber:user:admin validated {}
    """
    When I GET "/resources/cucumber/user/alice"
    Then the HTTP response status code is 404
