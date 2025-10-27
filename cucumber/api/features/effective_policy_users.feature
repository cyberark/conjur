@api
Feature: Fetching effective policy

  Background:
    Given I am the super-user
    When I can POST "/policies/cucumber/policy/root" with body from file "policy_users_1.yml"
    And I can PATCH "/policies/cucumber/policy/root" with body from file "policy_users_2.yml"
    And I can PATCH "/policies/cucumber/policy/rootpolicy" with body from file "policy_users_2.yml"

  @acceptance
  Scenario: As admin I can get effective policy using 'root'
    Given I am the super-user
    And I save my place in the audit log file for remote
    And I can GET "/policies/cucumber/policy/root"
    And the HTTP response status code is 200
    And the HTTP response content type is "application/x-yaml"
    Then the yaml result is:
    """
    ---
    - !user alice@rootpolicy.net
    - !user alice@rootpolicy.net@conjur.net
    - !user bob@rootpolicy.net
    - !user bob@rootpolicy.net-conjur.net
    - !user bob@rootpolicy.net@conjur.net
    - !user bob@rootpolicy.net@conjur.net@rootpolicy
    - !user bob@rootpolicy.net@rootpolicy
    - !policy
      id: rootpolicy
      body:
      - !user alice@rootpolicy.net@conjur.net
      - !user alice@rootpolicy.net
    - !policy
      id: rootpolicy.net
      body:
      - !policy
        id: conjur.net
        body:
        - !user alice
        - !user cecil
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" identifier="root" role_id="cucumber:user:admin"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="read"]
      cucumber:user:admin readed {:account=>"cucumber", :identifier=>"root", :role_id=>"cucumber:user:admin"}
    """
