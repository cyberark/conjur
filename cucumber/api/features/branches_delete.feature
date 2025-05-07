@api
Feature: Branches APIv2 tests - delete

  Background:
    Given I am the super-user
    And I can POST "/policies/cucumber/policy/root" with body from file "policy_cloud.yml"

  @acceptance
  Scenario: Deleting branch
    Given I add the secret value "v1" to the resource "cucumber:variable:data/safe1/branch1/alice-var"
    When I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I can GET "/branches/cucumber/data/safe1/branch1/alice-branch"
    And the HTTP response status code is 200
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I can GET "/secrets/cucumber/variable/data/safe1/branch1/alice-var"
    And I clear the "Accept" header
    And I clear the "Content-Type" header
    # setting update privilege for the parent
    And I can PATCH "/policies/cucumber/policy/data" with body:
    """
    ---
    - !permit
      role: !user safe1/alice
      privileges: [update]
      resource: !policy safe1
    """
    And I save my place in the audit log file for remote
    And I login as "alice@data-safe1"
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I can DELETE "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 204
#    And there is an audit record matching:
#    """
#    <85>1 * * conjur * branch\s
#    [auth@43868 user="cucumber:user:admin"]
#    [subject@43868 edge=""]
#    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
#    [action@43868 result="success" operation="delete"]\s
#    cucumber:user:admin successfully deleted branch data with URI path: '/branches/cucumber/data'
#    """
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I GET "/branches/cucumber/data/safe1/branch1"
    And the HTTP response status code is 404
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    # check using effective policy
    And I am the super-user
    And I set the "Accept" header to "application/x-yaml"
    And I can GET "/policies/cucumber/policy/data/safe1/"
    And the HTTP response content type is "application/x-yaml"
    Then the yaml result is:
    """
    ---
    - !policy
      id: safe1
      body:
      - !user alice
      - !policy
        id: alice-execute-only
        body: []
      - !policy
        id: alice-read-only
        body: []
      - !variable
        id: safe1-var1
        kind: description
        mime_type: text/plain
        annotations:
          description: Desc for var 1 in safe1
      - !group mygroup1
      - !permit
        role: !user alice
        privileges: [execute]
        resource: !policy alice-execute-only
      - !permit
        role: !user alice
        privileges: [read]
        resource: !policy alice-read-only
    """
    And I GET "/secrets/cucumber/variable/data/safe1/branch1/alice-var"
    And the HTTP response status code is 404

  @negative @acceptance
  Scenario: Deleting branch not possible
    And I am the super-user
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I set the "Content-Type" header to "application/json"
    And I can POST "/branches/cucumber" with body:
    """
    { "name": "alice-hidden",
      "branch": "data/safe1/branch1" }
    """
    And I login as "alice@data-safe1"
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I clear the "Content-Type" header
    And I DELETE "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 404
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
#    And there is an audit record matching:
#    """
#    <85>1 * * conjur * branch\s
#    [auth@43868 user="cucumber:user:admin"]
#    [subject@43868 edge=""]
#    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
#    [action@43868 result="success" operation="delete"]\s
#    cucumber:user:admin successfully deleted branch data with URI path: '/branches/cucumber/data'
#    """

  @negative @acceptance
  Scenario: Cannot delete root branch if no possibility
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I DELETE "/branches/cucumber"
    Then the HTTP response status code is 404
    And I DELETE "/branches/cucumber/"
    Then the HTTP response status code is 404
    And I DELETE "/branches/cucumber/root"
    Then the HTTP response status code is 404

  @negative @acceptance
  Scenario: Cannot delete a branch if no possibility
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I DELETE "/branches/cucumber/data/safe1"
    Then the HTTP response status code is 404

  @negative @acceptance
  Scenario: Cannot delete a branch with not existing parent branch
    And I am the super-user
    And I clear the "Accept" header
    And I clear the "Content-Type" header
    And I can PATCH "/policies/cucumber/policy/data/safe1/branch1" with body:
    """
    ---
    - !policy not_for_branch/branch2
    """
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    And I DELETE "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 404
    And the JSON should be:
    """
    { "code": "404",
      "message": "Branch 'data/safe1/branch1/not_for_branch/branch2' not found in account 'cucumber'" }
    """

  @acceptance
  Scenario: V2 header must be present
    Given I clear the "Accept" header
    And I DELETE "/branches/cucumber/data"
    Then the HTTP response status code is 400
    And the HTTP response content type is "application/x.secretsmgr.v2beta+json"
    And the JSON should be:
    """
    { "code": "400",
      "message": "CONJ00194W The api belongs to v2 APIs but it missing the version \"application/x.secretsmgr.v2beta+json\" in the Accept header" }
    """
