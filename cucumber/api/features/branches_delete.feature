@api
Feature: Branches APIv2 tests - delete

  Background:
    Given I am the super-user
    And I can POST "/policies/cucumber/policy/root" with body from file "policy_data.yml"

  @acceptance
  Scenario: Deleting branch
    Given I add the secret value "v1" to the resource "cucumber:variable:data/safe1/branch1/alice-var"
    And I set the Accept header to APIv2
    And I can GET "/branches/cucumber/data/safe1/branch1/alice-branch"
    And the HTTP response status code is 200
    And the HTTP response content type is APIv2
    And I set the Accept header to APIv2
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
    And I login as "alice@data-safe1"
    And I save my place in the audit log file for remote
    And I set the Accept header to APIv2
    When I can DELETE "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 204
    And there is an audit record matching:
    """
    <85>1 * * conjur * branch\s
    [auth@43868 user="cucumber:user:alice@data-safe1"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="success" operation="remove"]\s
    cucumber:user:alice@data-safe1 successfully removed branch data/safe1/branch1 with URI path: '/branches/cucumber/data/safe1/branch1'
    """
    And I set the Accept header to APIv2
    And I GET "/branches/cucumber/data/safe1/branch1"
    And the HTTP response status code is 404
    And the HTTP response content type is APIv2
    # check using effective policy
    And I am the super-user
    And I set the "Accept" header to "application/x-yaml"
    And I can GET "/policies/cucumber/policy/data/safe1/"
    And the HTTP response content type is "application/x-yaml"
    And the yaml result is:
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

  @acceptance
  Scenario: Deleting branch that is own owner
    And I login as "bob"
    And I set the "Accept" header to "application/x-yaml"
    And I can GET "/policies/cucumber/policy/some_branch"
    And the HTTP response content type is "application/x-yaml"
    And the yaml result is:
    """
    ---
    - !policy
      id: some_branch
      owner: !user /bob
      body:
      - !policy
        id: branch_own_owner
        owner: !policy /some_branch/branch_own_owner
        body:
        - !host myhost
        - !permit
          role: !user /bob
          privileges: [read, update]
          resource: !host myhost
      - !permit
        role: !user /bob
        privileges: [read, update]
        resource: !policy branch_own_owner
    """
    And I set the Accept header to APIv2
    When I can DELETE "/branches/cucumber/some_branch"
    Then the HTTP response status code is 204
    When I GET "/branches/cucumber/some_branch"
    Then the HTTP response status code is 404
    When I GET "/branches/cucumber/some_branch/branch_own_owner"
    Then the HTTP response status code is 404

  @negative @acceptance
  Scenario: Deleting branch not possible
    Given I am the super-user
    And I set the Accept header to APIv2
    And I set the "Content-Type" header to "application/json"
    And I can POST "/branches/cucumber" with body:
    """
    { "name": "alice-hidden",
      "branch": "data/safe1/branch1" }
    """
    And I login as "alice@data-safe1"
    And I set the Accept header to APIv2
    And I save my place in the audit log file for remote
    And I clear the "Content-Type" header
    When I DELETE "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 404
    And the HTTP response content type is APIv2
    And there is an audit record matching:
    """
    <85>1 * * conjur * branch\s
    [auth@43868 user="cucumber:user:alice@data-safe1"]
    [subject@43868 edge=""]
    [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
    [action@43868 result="failure" operation="remove"]\s
    cucumber:user:alice@data-safe1 failed to remove branch data/safe1/branch1 with URI path: '/branches/cucumber/data/safe1/branch1': Policy 'data/safe1/branch1/alice-hidden' not found in account 'cucumber'
    """

  @negative @acceptance
  Scenario: Cannot delete root branch if no possibility
    Given I set the Accept header to APIv2
    When I DELETE "/branches/cucumber"
    Then the HTTP response status code is 404
    When I DELETE "/branches/cucumber/"
    Then the HTTP response status code is 404
    When I DELETE "/branches/cucumber/root"
    Then the HTTP response status code is 404

  @negative @acceptance
  Scenario: Cannot delete a branch with not existing parent branch
    Given I am the super-user
    And I clear the "Accept" header
    And I clear the "Content-Type" header
    And I can PATCH "/policies/cucumber/policy/data/safe1/branch1" with body:
    """
    ---
    - !policy not_for_branch/branch2
    """
    And I set the Accept header to APIv2
    When I DELETE "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 204
    And I GET "/branches/cucumber/data/safe1/branch1"
    Then the HTTP response status code is 404
    And I GET "/branches/cucumber/data/safe1/branch1/not_for_branch/branch2"
    Then the HTTP response status code is 404

  @acceptance
  Scenario: V2 header must be present
    Given I clear the "Accept" header
    When I DELETE "/branches/cucumber/data"
    Then the HTTP response status code is 400
    And the HTTP response content type is APIv2
    And the JSON should be:
    """
    { "code": "400",
      "message": "CONJ00194W The api belongs to v2 APIs but it missing the version \"application/x.secretsmgr.v2beta+json\" in the Accept header" }
    """

  @acceptance
  Scenario: Deleting issuer branch
    Given I am the super-user
    And I successfully POST "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: conjur/issuers
      body: []
    """
    And I set the "Content-Type" header to "application/json"
    And I successfully POST "/issuers/cucumber" with body:
    """
    {
      "id": "aws-issuer-1",
      "max_ttl": 3000,
      "type": "aws",
      "data": {
        "access_key_id": "AKIAIOSFODNN7EXAMPLE",
        "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
      }
    }
    """
    And I clear the "Content-Type" header
    And I successfully GET "/issuers/cucumber/aws-issuer-1"
    And the HTTP response status code is 200
    And I set the "Accept" header to "application/x-yaml"
    And I set the "Content-Type" header to "application/x-yaml"
    And I can GET "/policies/cucumber/policy/conjur/issuers"
    And the yaml result is:
    """
    ---
    - !policy
      id: issuers
      owner: !user /admin
      body:
      - !policy
        id: aws-issuer-1
        body:
        - !policy
          id: delegation
          body:
          - !group consumers
      - !permit
        role: !group /conjur/issuers/aws-issuer-1/delegation/consumers
        privileges: [read, use]
        resource: !policy aws-issuer-1
    """
    And I set the "Accept" header to "application/x.secretsmgr.v2beta+json"
    When I can DELETE "/branches/cucumber/conjur/issuers/aws-issuer-1"
    And I clear the "Content-Type" header
    And I GET "/issuers/cucumber/aws-issuer-1"
    And the HTTP response status code is 404
    And I set the "Accept" header to "application/x-yaml"
    And I set the "Content-Type" header to "application/x-yaml"
    And I can GET "/policies/cucumber/policy/conjur/issuers"
    And the yaml result is:
    """
    ---
    - !policy
      id: issuers
      owner: !user /admin
      body: []
    """
