@api
@logged-in
@smoke
Feature: Issuers audits tests

  Background:
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

  Scenario: Successful audit when creating a issuer

    Given I am the super-user
    And I save my place in the audit log file for remote
    When I set the "Content-Type" header to "application/json"
    And I successfully POST "/issuers/cucumber" with body:
    """
    {
      "id": "aws-new-issuer",
      "max_ttl": 3000,
      "type": "aws",
      "data": {
        "access_key_id": "AKIAIOSFODNN7EXAMPLE",
        "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
      }
    }
    """
    Then the HTTP response status code is 201
    And there is an audit record matching:
    """
      <86>1 * - conjur * issuer
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" issuer="aws-new-issuer"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="add"]
      cucumber:user:admin added cucumber:issuer:aws-new-issuer
    """

  Scenario: Failure audit when creating an issuer

    Given I am a user named "alice"
    And I save my place in the audit log file for remote
    When I set the "Content-Type" header to "application/json"
    And I POST "/issuers/cucumber" with body:
    """
    {
      "id": "aws-new-issuer",
      "max_ttl": 3000,
      "type": "aws",
      "data": {
        "access_key_id": "AKIAIOSFODNN7EXAMPLE",
        "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
      }
    }
    """
    Then the HTTP response status code is 403
    And there is an audit record matching:
    """
      <84>1 * - conjur * issuer
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" issuer="aws-new-issuer"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="add"]
      cucumber:user:alice tried to add cucumber:issuer:aws-new-issuer: Policy 'conjur/issuers' not found in account 'cucumber'
    """

  Scenario: Successful audit when getting an issuer

    Given I am the super-user
    And I save my place in the audit log file for remote
    When I clear the "Content-Type" header
    And I successfully GET "/issuers/cucumber/aws-issuer-1"
    Then the HTTP response status code is 200
    And there is an audit record matching:
    """
      <86>1 * - conjur * issuer
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" issuer="aws-issuer-1"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="fetch"]
      cucumber:user:admin fetched cucumber:issuer:aws-issuer-1
    """

  Scenario: Failure audit when getting an issuer

    Given I am a user named "alice"
    And I save my place in the audit log file for remote
    When I clear the "Content-Type" header
    And I GET "/issuers/cucumber/aws-issuer-1"
    Then the HTTP response status code is 404
    And there is an audit record matching:
    """
      <84>1 * - conjur * issuer
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" issuer="aws-issuer-1"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="fetch"]
      cucumber:user:alice tried to fetch cucumber:issuer:aws-issuer-1: Issuer not found
    """

  Scenario: Successful audit when listing issuers

    Given I am the super-user
    And I save my place in the audit log file for remote
    When I clear the "Content-Type" header
    And I successfully GET "/issuers/cucumber"
    Then the HTTP response status code is 200
    And there is an audit record matching:
    """
      <86>1 * - conjur * issuer
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" issuer="*"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin listed issuers cucumber:issuer:*
    """

  Scenario: Failure audit when listing issuers

    Given I am a user named "alice"
    And I save my place in the audit log file for remote
    When I clear the "Content-Type" header
    And I GET "/issuers/cucumber"
    Then the HTTP response status code is 403
    And there is an audit record matching:
    """
      <84>1 * - conjur * issuer
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" issuer="*"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="list"]
      cucumber:user:alice tried to list issuers cucumber:issuer:*: Policy 'conjur/issuers' not found in account 'cucumber'
    """

  Scenario: Failure audit when deleting a issuer

    Given I am a user named "alice"
    And I save my place in the audit log file for remote
    When I clear the "Content-Type" header
    And I DELETE "/issuers/cucumber/aws-issuer-1"
    Then the HTTP response status code is 404
    And there is an audit record matching:
    """
      <84>1 * - conjur * issuer
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" issuer="aws-issuer-1"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"][action@43868 result="failure" operation="remove"]
      cucumber:user:alice tried to remove cucumber:issuer:aws-issuer-1: Policy 'conjur/issuers' not found in account 'cucumber'
    """

  Scenario: Successful audit when deleting a issuer

    Given I am the super-user
    And I successfully POST "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: data/dynamic
      body:
      - !variable
        id: my-ephemeral-secret
        annotations:
          dynamic/issuer: aws-issuer-1
          dynamic/method: assume-role

    - !policy
      id: data
      body:
      - !variable
        id: my-non-ephemeral-secret
    """
    And I successfully POST "/policies/cucumber/policy/data/dynamic" with body:
    """
    - !policy
      id: inner-policy
      body:
      - !variable
        id: my-other-ephemeral-secret
        annotations:
          dynamic/issuer: aws-issuer-1
          dynamic/method: assume-role
    """
    And I save my place in the audit log file for remote
    When I clear the "Content-Type" header
    And I successfully DELETE "/issuers/cucumber/aws-issuer-1"
    Then the HTTP response status code is 204
    And there is an audit record matching:
    """
      <86>1 * - conjur * issuer
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" issuer="aws-issuer-1"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="remove"]
      cucumber:user:admin removed cucumber:issuer:aws-issuer-1
    """
    And there is an audit record matching:
    """
      <86>1 * - conjur * variable
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" issuer="aws-issuer-1" resource_id="cucumber:variable:data/dynamic/my-ephemeral-secret"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="remove"]
      cucumber:variable:data/dynamic/my-ephemeral-secret removed as a result of the removal of cucumber:issuer:aws-issuer-1
    """
    And there is an audit record matching:
    """
      <86>1 * - conjur * variable
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" issuer="aws-issuer-1" resource_id="cucumber:variable:data/dynamic/inner-policy/my-other-ephemeral-secret"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="remove"]
      cucumber:variable:data/dynamic/inner-policy/my-other-ephemeral-secret removed as a result of the removal of cucumber:issuer:aws-issuer-1
    """
