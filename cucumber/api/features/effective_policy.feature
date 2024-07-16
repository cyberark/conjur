@api
Feature: Fetching effective policy

  Background:
    Given I am the super-user
    When I can POST "/policies/cucumber/policy/root" with body from file "policy_rootpolicy.yml"
    And I can PATCH "/policies/cucumber/policy/root" with body from file "policy_acme_root.yml":
    And I can PATCH "/policies/cucumber/policy/rootpolicy" with body from file "policy_acme.yml"

  @acceptance
  Scenario: As admin I can get effective policy using 'root'
    Given I am the super-user
    And I save my place in the audit log file for remote
    And I can GET "/policies/cucumber/policy/root"
    And the HTTP response status code is 200
    And the HTTP response content type is "application/x-yaml"
    Then the yaml result is like in file: "policy_acme_eff_pol_root.yml"
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
  Scenario: As admin I can get effective policy
    Given I am the super-user
    And I save my place in the audit log file for remote
    And I can GET "/policies/cucumber/policy/rootpolicy"
    And the HTTP response content type is "application/x-yaml"
    Then the yaml result is like in file: "policy_acme_eff_pol.yml"
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" identifier="rootpolicy" role_id="cucumber:user:admin"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="read"]
      cucumber:user:admin readed {:account=>"cucumber", :identifier=>"rootpolicy", :role_id=>"cucumber:user:admin"}
    """

  @acceptance
  Scenario: As admin I can get effective policy starting with some subpolicy
    Given I am the super-user
    And I can GET "/policies/cucumber/policy/rootpolicy/acme-adm/outer-adm"
    And the HTTP response content type is "application/x-yaml"
    Then the yaml result is like in file: "policy_acme_eff_pol_outer.yml"

  @acceptance
  Scenario: As Alice I can get effective policy starting with some subpolicy of which I am owner
    Given I login as "cucumber:user:ali@rootpolicy-acme-adm"
    And I can GET "/policies/cucumber/policy/rootpolicy/acme-adm/outer-adm"
    And the HTTP response content type is "application/x-yaml"
    Then the yaml result is like in file: "policy_acme_eff_pol_outer.yml"
    And I can GET "/policies/cucumber/policy/rootpolicy/acme-adm/outer-adm/inner-adm"
    And the HTTP response status code is 200
    And the HTTP response content type is "application/x-yaml"
    And I can GET "/policies/cucumber/policy/rootpolicy/acme-adm/outer-adm/inner-adm/data-adm"
    And the HTTP response status code is 200
    And the HTTP response content type is "application/x-yaml"

  @negative @acceptance
  Scenario: As Alice I cannot get effective policy starting with root
    When I login as "cucumber:user:ali@rootpolicy-acme-adm"
    And I GET "/policies/cucumber/policy/root"
    Then the HTTP response status code is 404

  @negative @acceptance
  Scenario: As Alice I cannot get effective policy starting with rootpolicy
    When I login as "cucumber:user:ali@rootpolicy-acme-adm"
    And I GET "/policies/cucumber/policy/rootpolicy"
    Then the HTTP response status code is 404

  @acceptance
  Scenario: As admin I can get effective policy with depth 0
    Given I am the super-user
    And I can GET "/policies/cucumber/policy/rootpolicy?depth=0"
    And the HTTP response content type is "application/x-yaml"
    Then the yaml result is:
    """
    - !policy
      id: rootpolicy
      body: []
    """

  @acceptance
  Scenario: As admin I can get effective policy with depth 1
    Given I am the super-user
    And I can GET "/policies/cucumber/policy/rootpolicy/acme-adm/outer?depth=1"
    And the HTTP response content type is "application/x-yaml"
    Then the yaml result is:
    """
    - !policy
      id: outer
      body:
        - !policy
          id: adm
          body: []
    """

  @acceptance
  Scenario: As admin I can get effective policy with depth 2
    Given I am the super-user
    And I can GET "/policies/cucumber/policy/rootpolicy/acme-adm/outer?depth=2"
    And the HTTP response content type is "application/x-yaml"
    Then the yaml result is:
    """
    ---
    - !policy
      id: outer
      body:
        - !policy
          id: adm
          body:
            - !policy
              id: inner
              body: []
    """

  @negative @acceptance
  Scenario: As admin I can get effective policy with limit 3
    Given I am the super-user
    And I GET "/policies/cucumber/policy/rootpolicy?limit=3"
    Then the HTTP response status code is 422

  @acceptance
  Scenario: As admin I can get effective policy with depth and limit
    Given I am the super-user
    And I can GET "/policies/cucumber/policy/rootpolicy/acme-adm/outer?depth=1;limit=10"
    Then the yaml result is:
    """
    - !policy
      id: outer
      body:
        - !policy
          id: adm
          body: []
    """

  @acceptance
  Scenario: As admin I can get effective policy for subpolicy with depth and limit
    Given I am the super-user
    And I can GET "/policies/cucumber/policy/rootpolicy/acme-adm/outer-adm?depth=1;limit=16"
    Then the yaml result is:
    """
    ---
    - !policy
      id: outer-adm
      owner: !user /rootpolicy/acme-adm/ali
      body:
      - !user
        id: bob
        restricted_to: [172.17.0.3/32, 10.0.0.0/24]
      - !policy
        id: inner-adm
        owner: !user /rootpolicy/acme-adm/outer-adm/bob
        body:
        - !user cac
      - !policy
        id: root
        body:
        - !user usr
      - !group grp-outer-adm
      - !permit
        role: !group grp-outer-adm
        privileges: [execute, read]
        resource: !policy inner-adm
      - !permit
        role: !user bob
        privileges: [create, read, update]
        resource: !policy inner-adm
    """
