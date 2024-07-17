@api
Feature: Fetching effective policy in json format

  Background:
    Given I am the super-user
    When I can POST "/policies/cucumber/policy/root" with body from file "policy_rootpolicy.yml"
    And I can PATCH "/policies/cucumber/policy/root" with body from file "policy_acme_root.yml":
    And I can PATCH "/policies/cucumber/policy/rootpolicy" with body from file "policy_acme.yml"

  @acceptance
  Scenario: As admin I can get effective policy in json format using 'root'
    Given I am the super-user
    And I save my place in the audit log file for remote
    And I set the "content-Type" header to "application/json"
    And I can GET "/policies/cucumber/policy/root"
    And the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" identifier="root" role_id="cucumber:user:admin"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="read"]
      cucumber:user:admin readed {:account=>"cucumber", :identifier=>"root", :role_id=>"cucumber:user:admin"}
    """
    And the JSON response should be:
    """
    [{"user":{"id":"rot"}},{"policy":{"id":"pol-root","body":[]}},{"policy":{"id":"rootpolicy","body":[{"policy":{"id":"acme-adm","owner":{"user":"/admin"},"annotations":{"description":"Policy acme in root made by admin","type":"acme-adm-type"},"body":[{"host":{"id":"outer-host","owner":{"policy":"/rootpolicy/acme-adm/outer-adm-inner-adm"}}},{"policy":{"id":"outer","body":[{"policy":{"id":"adm","body":[{"policy":{"id":"inner","body":[{"policy":{"id":"adm","body":[]}}]}}]}}]}},{"policy":{"id":"outer-adm","owner":{"user":"/rootpolicy/acme-adm/ali"},"body":[{"group":{"id":"grp-outer-adm"}},{"policy":{"id":"inner-adm","owner":{"user":"/rootpolicy/acme-adm/outer-adm/bob"},"body":[{"policy":{"id":"data-adm","body":[{"group":{"id":"data-adm-grp1"}},{"group":{"id":"data-adm-grp2","owner":{"host-factory":"/rootpolicy/acme-adm/outer-adm/inner-adm/data-adm/data-adm-hf2"},"annotations":{"description":"annotation description"}}},{"host-factory":{"id":"data-adm-hf1","layers":[{"layer":"data-adm-lyr1"}]}},{"host-factory":{"id":"data-adm-hf2","owner":{"host":"/rootpolicy/acme-adm/outer-adm/inner-adm/data-adm/data-adm-hst2"},"layers":[{"layer":"data-adm-lyr1"},{"layer":"data-adm-lyr2"}],"annotations":{"description":"annotation description"}}},{"host":{"id":"data-adm-hst1"}},{"host":{"id":"data-adm-hst2","restricted_to":["172.17.0.3/32","10.0.0.0/24"]}},{"layer":{"id":"data-adm-lyr1"}},{"layer":{"id":"data-adm-lyr2"}},{"variable":{"id":"inner-data-adm-var1"}},{"variable":{"id":"inner-data-adm-var2","kind":"description","mime_type":"text/plain","annotations":{"description":"Desc for var 2 in inner-adm"}}},{"webservice":{"id":"inner-data-adm-ws1"}},{"webservice":{"id":"inner-data-adm-ws2","annotations":{"description":"Desc for var 2 in inner-adm"}}},{"webservice":{"id":"inner-data-adm-ws3"}}]}},{"variable":{"id":"inner-adm-var1","kind":"description","mime_type":"text/plain","annotations":{"description":"Desc for var 2 in inner-adm"}}},{"variable":{"id":"inner-adm-var2","kind":"description","mime_type":"text/plain","annotations":{"description":"Desc for var 2 in inner-adm"}}},{"user":{"id":"cac"}}]}},{"permit":{"role":{"group":"grp-outer-adm"},"privileges":["execute","read"],"resource":{"policy":"inner-adm"}}},{"permit":{"role":{"user":"bob"},"privileges":["create","read","update"],"resource":{"policy":"inner-adm"}}},{"policy":{"id":"root","body":[{"user":{"id":"usr"}}]}},{"grant":{"role":{"group":"grp-outer-adm"},"members":[{"user":"/rootpolicy/acme-adm/ala"},{"user":"/rootpolicy/acme-adm/ale"},{"user":"/rootpolicy/acme-adm/ali"},{"user":"/rootpolicy/acme-adm/alo"},{"user":"/rootpolicy/acme-adm/aly"}]}},{"grant":{"role":{"user":"bob"},"members":[{"user":"/rootpolicy/acme-adm/ali"}]}},{"user":{"id":"bob","restricted_to":["172.17.0.3/32","10.0.0.0/24"]}}]}},{"policy":{"id":"outer-adm-inner-adm","body":[]}},{"user":{"id":"ala"}},{"user":{"id":"ale"}},{"user":{"id":"ali"}},{"user":{"id":"alo"}},{"user":{"id":"aly"}},{"grant":{"role":{"user":"ali"},"members":[{"user":"/rot"}]}}]}}]}},{"variable":{"id":"root-var"}},{"variable":{"id":"with/slash"}},{"webservice":{"id":"root-ws"}},{"host":{"id":"root-hst"}},{"layer":{"id":"root-lyr"}},{"host-factory":{"id":"root-hf","layers":[{"layer":"root-lyr"}]}},{"group":{"id":"root-grp"}},{"grant":{"role":{"group":"root-grp"},"members":[{"user":"/rot"}]}},{"permit":{"role":{"group":"root-grp"},"privileges":["execute","read"],"resource":{"policy":"rootpolicy"}}}]
    """

  @acceptance
  Scenario: As admin I can get effective policy in json format using 'rootpolicy'
    Given I am the super-user
    And I save my place in the audit log file for remote
    And I set the "Content-Type" header to "application/json"
    And I can GET "/policies/cucumber/policy/rootpolicy"
    And the HTTP response status code is 200
    And the HTTP response content type is "application/json"
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" identifier="rootpolicy" role_id="cucumber:user:admin"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="read"]
      cucumber:user:admin readed {:account=>"cucumber", :identifier=>"rootpolicy", :role_id=>"cucumber:user:admin"}
    """
    And the JSON response should be:
    """
    [{"policy":{"id":"rootpolicy","body":[{"policy":{"id":"acme-adm","owner":{"user":"/admin"},"annotations":{"description":"Policy acme in root made by admin","type":"acme-adm-type"},"body":[{"host":{"id":"outer-host","owner":{"policy":"/rootpolicy/acme-adm/outer-adm-inner-adm"}}},{"policy":{"id":"outer","body":[{"policy":{"id":"adm","body":[{"policy":{"id":"inner","body":[{"policy":{"id":"adm","body":[]}}]}}]}}]}},{"policy":{"id":"outer-adm","owner":{"user":"/rootpolicy/acme-adm/ali"},"body":[{"group":{"id":"grp-outer-adm"}},{"policy":{"id":"inner-adm","owner":{"user":"/rootpolicy/acme-adm/outer-adm/bob"},"body":[{"policy":{"id":"data-adm","body":[{"group":{"id":"data-adm-grp1"}},{"group":{"id":"data-adm-grp2","owner":{"host-factory":"/rootpolicy/acme-adm/outer-adm/inner-adm/data-adm/data-adm-hf2"},"annotations":{"description":"annotation description"}}},{"host-factory":{"id":"data-adm-hf1","layers":[{"layer":"data-adm-lyr1"}]}},{"host-factory":{"id":"data-adm-hf2","owner":{"host":"/rootpolicy/acme-adm/outer-adm/inner-adm/data-adm/data-adm-hst2"},"layers":[{"layer":"data-adm-lyr1"},{"layer":"data-adm-lyr2"}],"annotations":{"description":"annotation description"}}},{"host":{"id":"data-adm-hst1"}},{"host":{"id":"data-adm-hst2","restricted_to":["172.17.0.3/32","10.0.0.0/24"]}},{"layer":{"id":"data-adm-lyr1"}},{"layer":{"id":"data-adm-lyr2"}},{"variable":{"id":"inner-data-adm-var1"}},{"variable":{"id":"inner-data-adm-var2","kind":"description","mime_type":"text/plain","annotations":{"description":"Desc for var 2 in inner-adm"}}},{"webservice":{"id":"inner-data-adm-ws1"}},{"webservice":{"id":"inner-data-adm-ws2","annotations":{"description":"Desc for var 2 in inner-adm"}}},{"webservice":{"id":"inner-data-adm-ws3"}}]}},{"variable":{"id":"inner-adm-var1","kind":"description","mime_type":"text/plain","annotations":{"description":"Desc for var 2 in inner-adm"}}},{"variable":{"id":"inner-adm-var2","kind":"description","mime_type":"text/plain","annotations":{"description":"Desc for var 2 in inner-adm"}}},{"user":{"id":"cac"}}]}},{"permit":{"role":{"group":"grp-outer-adm"},"privileges":["execute","read"],"resource":{"policy":"inner-adm"}}},{"permit":{"role":{"user":"bob"},"privileges":["create","read","update"],"resource":{"policy":"inner-adm"}}},{"policy":{"id":"root","body":[{"user":{"id":"usr"}}]}},{"grant":{"role":{"group":"grp-outer-adm"},"members":[{"user":"/rootpolicy/acme-adm/ala"},{"user":"/rootpolicy/acme-adm/ale"},{"user":"/rootpolicy/acme-adm/ali"},{"user":"/rootpolicy/acme-adm/alo"},{"user":"/rootpolicy/acme-adm/aly"}]}},{"grant":{"role":{"user":"bob"},"members":[{"user":"/rootpolicy/acme-adm/ali"}]}},{"user":{"id":"bob","restricted_to":["172.17.0.3/32","10.0.0.0/24"]}}]}},{"policy":{"id":"outer-adm-inner-adm","body":[]}},{"user":{"id":"ala"}},{"user":{"id":"ale"}},{"user":{"id":"ali"}},{"user":{"id":"alo"}},{"user":{"id":"aly"}}]}}]}}]
    """

  @acceptance
  Scenario: As admin I can get effective policy in json format starting with some subpolicy
    Given I am the super-user
    When I set the "Content-Type" header to "application/json"
    And I can GET "/policies/cucumber/policy/rootpolicy/acme-adm/outer-adm"
    Then the HTTP response content type is "application/json"
    And the JSON response should be:
    """
    [{"policy":{"id":"outer-adm","owner":{"user":"/rootpolicy/acme-adm/ali"},"body":[{"group":{"id":"grp-outer-adm"}},{"policy":{"id":"inner-adm","owner":{"user":"/rootpolicy/acme-adm/outer-adm/bob"},"body":[{"policy":{"id":"data-adm","body":[{"group":{"id":"data-adm-grp1"}},{"group":{"id":"data-adm-grp2","owner":{"host-factory":"/rootpolicy/acme-adm/outer-adm/inner-adm/data-adm/data-adm-hf2"},"annotations":{"description":"annotation description"}}},{"host-factory":{"id":"data-adm-hf1","layers":[{"layer":"data-adm-lyr1"}]}},{"host-factory":{"id":"data-adm-hf2","owner":{"host":"/rootpolicy/acme-adm/outer-adm/inner-adm/data-adm/data-adm-hst2"},"layers":[{"layer":"data-adm-lyr1"},{"layer":"data-adm-lyr2"}],"annotations":{"description":"annotation description"}}},{"host":{"id":"data-adm-hst1"}},{"host":{"id":"data-adm-hst2","restricted_to":["172.17.0.3/32","10.0.0.0/24"]}},{"layer":{"id":"data-adm-lyr1"}},{"layer":{"id":"data-adm-lyr2"}},{"variable":{"id":"inner-data-adm-var1"}},{"variable":{"id":"inner-data-adm-var2","kind":"description","mime_type":"text/plain","annotations":{"description":"Desc for var 2 in inner-adm"}}},{"webservice":{"id":"inner-data-adm-ws1"}},{"webservice":{"id":"inner-data-adm-ws2","annotations":{"description":"Desc for var 2 in inner-adm"}}},{"webservice":{"id":"inner-data-adm-ws3"}}]}},{"variable":{"id":"inner-adm-var1","kind":"description","mime_type":"text/plain","annotations":{"description":"Desc for var 2 in inner-adm"}}},{"variable":{"id":"inner-adm-var2","kind":"description","mime_type":"text/plain","annotations":{"description":"Desc for var 2 in inner-adm"}}},{"user":{"id":"cac"}}]}},{"permit":{"role":{"group":"grp-outer-adm"},"privileges":["execute","read"],"resource":{"policy":"inner-adm"}}},{"permit":{"role":{"user":"bob"},"privileges":["create","read","update"],"resource":{"policy":"inner-adm"}}},{"policy":{"id":"root","body":[{"user":{"id":"usr"}}]}},{"user":{"id":"bob","restricted_to":["172.17.0.3/32","10.0.0.0/24"]}}]}}]
    """
