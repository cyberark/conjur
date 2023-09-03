@api
@logged-in
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
        "access_key_id": "my-key-id",
        "secret_access_key": "my-key-secret"
      }
    }
    """

  @smoke
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
        "access_key_id": "my-key-id",
        "secret_access_key": "my-key-secret"
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

  @smoke
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
        "access_key_id": "my-key-id",
        "secret_access_key": "my-key-secret"
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

  @smoke
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

  @smoke
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

  @smoke
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

  @smoke
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

  @smoke
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

  @smoke
  Scenario: Successful audit when deleting a issuer

    Given I am the super-user
    And I successfully POST "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: data/ephemerals
      body:
      - !variable
        id: my-ephemeral-secret
        annotations:
          ephemeral/issuer: aws-issuer-1

    - !policy
      id: data
      body:
      - !variable
        id: my-non-ephemeral-secret
    """
    And I successfully POST "/policies/cucumber/policy/data/ephemerals" with body:
    """
    - !policy
      id: inner-policy
      body:
      - !variable
        id: my-other-ephemeral-secret
        annotations:
          ephemeral/issuer: aws-issuer-1
    """
    And I save my place in the audit log file for remote
    When I clear the "Content-Type" header
    And I successfully DELETE "/issuers/cucumber/aws-issuer-1"
    Then the HTTP response status code is 200
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
      [subject@43868 account="cucumber" issuer="aws-issuer-1" resource_id="cucumber:variable:data/ephemerals/my-ephemeral-secret"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="remove"]
      cucumber:variable:data/ephemerals/my-ephemeral-secret removed as a result of the removal of cucumber:issuer:aws-issuer-1
    """
    And there is an audit record matching:
    """
      <86>1 * - conjur * variable
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" issuer="aws-issuer-1" resource_id="cucumber:variable:data/ephemerals/inner-policy/my-other-ephemeral-secret"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="remove"]
      cucumber:variable:data/ephemerals/inner-policy/my-other-ephemeral-secret removed as a result of the removal of cucumber:issuer:aws-issuer-1
    """
