@api
Feature: Updating policies

  The initial policy is loaded using the `conjurctl` command line tool,
  typically running as a one-off container command inside the container itself.

  The initial policy create sub-policies which can be modified by privileged users.

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !user alice
    - !user bob
    - !user eve

    - !policy
      id: dev
      owner: !user alice
      body:
      - !policy
        id: db

    - !grant
      role: !policy dev/db
      member: !user bob

    - !permit
      resource: !policy dev/db
      privilege: [ update ]
      role: !user bob

    - !permit
      resource: !policy dev/db
      privilege: [ read ]
      role: !user eve
    """

  @smoke
  Scenario: A role with "update" privilege can update a policy.
    When I login as "bob"
    And I save my place in the audit log file for remote
    Then I successfully PUT "/policies/cucumber/policy/dev/db" with body:
    """
    - !layer
    """
    And I successfully GET "/resources/cucumber/layer/dev/db"
    Then there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:bob"]
      [subject@43868 resource="cucumber:layer:dev/db"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="add"]
      [policy@43868 id="cucumber:policy:dev/db" version="1"]
      cucumber:user:bob added resource cucumber:layer:dev/db
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:bob"]
      [subject@43868 role="cucumber:layer:dev/db"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="add"]
      [policy@43868 id="cucumber:policy:dev/db" version="1"]
      cucumber:user:bob added role cucumber:layer:dev/db
    """
    And there is an audit record matching:
    """
      <85>1 * * conjur * policy
      [auth@43868 user="cucumber:user:bob"]
      [subject@43868 role="cucumber:layer:dev/db" owner="cucumber:policy:dev/db"]
      [client@43868 ip="\d+\.\d+\.\d+\.\d+"]
      [action@43868 result="success" operation="add"]
      [policy@43868 id="cucumber:policy:dev/db" version="1"]
      cucumber:user:bob added ownership of cucumber:policy:dev/db in cucumber:layer:dev/db
    """

  @negative @acceptance
  Scenario: A role without any privilege cannot update a policy.
    When I login as "eve"
    When I PUT "/policies/cucumber/policy/dev/db" with body:
    """
    - !layer
    """
    Then the HTTP response status code is 403

  @acceptance
  Scenario: A policy with special characters and no content type header
    When I use curl to load a policy with special characters and no content type
    Then the command is successful

  @acceptance
  Scenario: A large policy with no content type header
    When I clear the "Content-Type" header
    And I load a large policy with POST
    Then the HTTP response status code is 201
    And the HTTP response content type is "application/json"
