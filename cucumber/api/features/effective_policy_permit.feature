@api
Feature: Fetching effective policy

  Background:
    Given I am the super-user

  @acceptance
  Scenario: As admin I can get effective policy containing permits with roles in different policy than resource
    When I can POST "/policies/cucumber/policy/root" with body from file "policy_permit.yml"
    And I save my place in the audit log file for remote
    And I can GET "/policies/cucumber/policy/root"
    And the HTTP response status code is 200
    And the HTTP response content type is "application/x-yaml"
    Then the yaml result is like in file: "policy_eff_pol_permit.yml"
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" identifier="root" role_id="cucumber:user:admin"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="read"]
      cucumber:user:admin readed {:account=>"cucumber", :identifier=>"root", :role_id=>"cucumber:user:admin"}
    """

  @acceptance
  Scenario: Result of effective policy with permit can be loaded again
    When I can POST "/policies/cucumber/policy/root" with body from file "policy_eff_pol_permit.yml"
    And I save my place in the audit log file for remote
    And I can GET "/policies/cucumber/policy/root"
    And the HTTP response status code is 200
    And the HTTP response content type is "application/x-yaml"
    Then the yaml result is like in file: "policy_eff_pol_permit.yml"

  @acceptance
  Scenario: As admin I can get effective policy containing permits with roles in different policy than resource - group id like path
    When I can POST "/policies/cucumber/policy/root" with body from file "policy_permit-1.yml"
    And I save my place in the audit log file for remote
    And I can GET "/policies/cucumber/policy/root"
    And the HTTP response status code is 200
    And the HTTP response content type is "application/x-yaml"
    Then the yaml result is like in file: "policy_eff_pol_permit-1.yml"
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" identifier="root" role_id="cucumber:user:admin"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="read"]
      cucumber:user:admin readed {:account=>"cucumber", :identifier=>"root", :role_id=>"cucumber:user:admin"}
    """

  @acceptance
  Scenario: Result of effective policy with permit can be loaded again - group id like path
    When I can POST "/policies/cucumber/policy/root" with body from file "policy_eff_pol_permit-1.yml"
    And I save my place in the audit log file for remote
    And I can GET "/policies/cucumber/policy/root"
    And the HTTP response status code is 200
    And the HTTP response content type is "application/x-yaml"
    Then the yaml result is like in file: "policy_eff_pol_permit-1.yml"