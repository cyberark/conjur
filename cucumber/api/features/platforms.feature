@api
@logged-in
Feature: Platforms audits tests

  Background:
    Given I am the super-user
    And I successfully POST "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: data/platforms
      body: []
    """
    And I set the "Content-Type" header to "application/json"
    And I successfully POST "/platforms/cucumber" with body:
    """
    {
      "id": "aws-platform-1",
      "max_ttl": 3000,
      "type": "aws",
      "data": {
        "access_key_id": "my-key-id",
        "access_key_secret": "my-key-secret"
      }
    }
    """

  @smoke
  Scenario: Successful audit when creating a platform

    Given I am the super-user
    And I save my place in the audit log file for remote
    When I set the "Content-Type" header to "application/json"
    And I successfully POST "/platforms/cucumber" with body:
    """
    {
      "id": "aws-new-platform",
      "max_ttl": 3000,
      "type": "aws",
      "data": {
        "access_key_id": "my-key-id",
        "access_key_secret": "my-key-secret"
      }
    }
    """
    Then the HTTP response status code is 201
    And there is an audit record matching:
    """
      <86>1 * - conjur * platform
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" platform="aws-new-platform"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="create"]
      cucumber:user:admin performed create on platform cucumber:platform:aws-new-platform
    """

  @smoke
  Scenario: Failure audit when creating a platform

    Given I am a user named "alice"
    And I save my place in the audit log file for remote
    When I set the "Content-Type" header to "application/json"
    And I POST "/platforms/cucumber" with body:
    """
    {
      "id": "aws-new-platform",
      "max_ttl": 3000,
      "type": "aws",
      "data": {
        "access_key_id": "my-key-id",
        "access_key_secret": "my-key-secret"
      }
    }
    """
    Then the HTTP response status code is 403
    And there is an audit record matching:
    """
      <84>1 * - conjur * platform
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" platform="aws-new-platform"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="create"]
      cucumber:user:alice tried to create platform cucumber:platform:aws-new-platform: Policy 'data/platforms' not found in account 'cucumber'
    """

  @smoke
  Scenario: Successful audit when getting a platform

    Given I am the super-user
    And I save my place in the audit log file for remote
    When I clear the "Content-Type" header
    And I successfully GET "/platforms/cucumber/aws-platform-1"
    Then the HTTP response status code is 200
    And there is an audit record matching:
    """
      <86>1 * - conjur * platform
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" platform="aws-platform-1"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="get"]
      cucumber:user:admin performed get on platform cucumber:platform:aws-platform-1
    """

  @smoke
  Scenario: Failure audit when getting a platform

    Given I am a user named "alice"
    And I save my place in the audit log file for remote
    When I clear the "Content-Type" header
    And I GET "/platforms/cucumber/aws-platform-1"
    Then the HTTP response status code is 404
    And there is an audit record matching:
    """
      <84>1 * - conjur * platform
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" platform="aws-platform-1"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="get"]
      cucumber:user:alice tried to get platform cucumber:platform:aws-platform-1: Platform not found
    """

  @smoke
  Scenario: Successful audit when listing platforms

    Given I am the super-user
    And I save my place in the audit log file for remote
    When I clear the "Content-Type" header
    And I successfully GET "/platforms/cucumber"
    Then the HTTP response status code is 200
    And there is an audit record matching:
    """
      <86>1 * - conjur * platform
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" platform="*"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="list"]
      cucumber:user:admin listed platforms cucumber:platform:*
    """

  @smoke
  Scenario: Failure audit when listing platforms

    Given I am a user named "alice"
    And I save my place in the audit log file for remote
    When I clear the "Content-Type" header
    And I GET "/platforms/cucumber"
    Then the HTTP response status code is 403
    And there is an audit record matching:
    """
      <84>1 * - conjur * platform
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" platform="*"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="failure" operation="list"]
      cucumber:user:alice tried to list platforms cucumber:platform:*: Policy 'data/platforms' not found in account 'cucumber'
    """

  @smoke
  Scenario: Failure audit when deleting a platform

    Given I am a user named "alice"
    And I save my place in the audit log file for remote
    When I clear the "Content-Type" header
    And I DELETE "/platforms/cucumber/aws-platform-1"
    Then the HTTP response status code is 404
    And there is an audit record matching:
    """
      <84>1 * - conjur * platform
      [auth@43868 user="cucumber:user:alice"]
      [subject@43868 account="cucumber" platform="aws-platform-1"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"][action@43868 result="failure" operation="delete"]
      cucumber:user:alice tried to delete platform cucumber:platform:aws-platform-1: Policy 'data/platforms' not found in account 'cucumber'
    """

  @smoke
  Scenario: Successful audit when deleting a platform

    Given I am the super-user
    And I save my place in the audit log file for remote
    When I clear the "Content-Type" header
    And I successfully DELETE "/platforms/cucumber/aws-platform-1"
    Then the HTTP response status code is 200
    And there is an audit record matching:
    """
      <86>1 * - conjur * platform
      [auth@43868 user="cucumber:user:admin"]
      [subject@43868 account="cucumber" platform="aws-platform-1"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="delete"]
      cucumber:user:admin performed delete on platform cucumber:platform:aws-platform-1
    """