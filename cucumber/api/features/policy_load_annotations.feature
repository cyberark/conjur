@api
Feature: Updating Policies with Annotations

  The following describes the use-case for the different policy load types:
  - PUT requests replace an existing policy, or loads a nonexistent one.
    Requires update privilege on the target policy.
  - POST requests add data to an existing policy.
    Requires create privilege on the target policy.
  - PATCH requests modify an existing policy.
    Requires update privilege on the target policy.

  Here is a summary of the current behavior of Conjur's policy API, recording
  the result of a host with [create|update] privilege on a policy branch
  attempting to [add new|update existing] annotations to a resource in that
  policy branch via a [PUT|POST|PATCH]-based policy load attempt:
  - create / add new         / PUT   :   EXPECTED FAIL - 403 on policy load
  - create / add new         / POST  :   EXPECTED SUCCESS
  - create / add new         / PATCH :   EXPECTED FAIL - 403 on policy load
  - create / update existing / PUT   :   EXPECTED FAIL - 403 on policy load
  - create / update existing / POST  :   EXPECTED FAIL - 20x on policy load, annot not updated
  - create / update existing / PATCH :   EXPECTED FAIL - 403 on policy load
  - update / add new         / PUT   :   EXPECTED SUCCESS
  - update / add new         / POST  :   EXPECTED FAIL - 403 on policy load
  - update / add new         / PATCH :   EXPECTED SUCCESS
  - update / update existing / PUT   :   EXPECTED SUCCESS
  - update / update existing / POST  :   EXPECTED FAIL - 403 on policy load
  - update / update existing / PATCH :   EXPECTED SUCCESS

  All these outcomes align with our expectations, but one may not align with
  user expectations: ( create / update existing / POST ). A user may expect that
  a policy load that tries and fails to update the content of a given annotation
  should either provide a warning or fail outright.

  How can we update how we handle policy to fail in this case?

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy hosts
    """
    And I successfully PUT "/policies/cucumber/policy/hosts" with body:
    """
    - !host
      id: annotated
      annotations:
        description: Already annotated
    
    - !host to-annotate
    """
    And I successfully POST "/policies/cucumber/policy/root" with body:
    """
    - !user alice
    - !user bob

    - !permit
      resource: !policy hosts
      privilege: [ read, update ]
      role: !user bob

    - !permit
      resource: !host hosts/annotated
      privilege: [ read ]
      role: !user bob
    
    - !permit
      resource: !host hosts/to-annotate
      privilege: [ read ]
      role: !user bob

    - !permit
      resource: !policy hosts
      privilege: [ read, create ]
      role: !user alice

    - !permit
      resource: !host hosts/annotated
      privilege: [ read ]
      role: !user alice

    - !permit
      resource: !host hosts/to-annotate
      privilege: [ read ]
      role: !user alice
    """

  @negative
  @acceptance
  Scenario: User with create privilege can NOT add new annotations with PUT
    When I login as "alice"
    And I save my place in the log file
    Then I PUT "/policies/cucumber/policy/hosts" with body:
    """
    - !host
      id: to-annotate
      annotations:
        description: Success
    """
    Then the HTTP response status code is 403
    And The following appears in the log after my savepoint:
    """
    CONJ00006E 'cucumber:user:alice' does not have 'update' privilege on cucumber:policy:hosts
    """

  @smoke
  @acceptance
  Scenario: User with create privilege can add new annotations with POST
    When I login as "alice"
    Then I successfully POST "/policies/cucumber/policy/hosts" with body:
    """
    - !host
      id: to-annotate
      annotations:
        description: Success
    """
    And I successfully GET "/resources/cucumber/host/hosts%2Fto-annotate"
    Then the JSON should be:
    """
    {
      "annotations": [
        {
          "name": "description",
          "policy": "cucumber:policy:hosts",
          "value": "Success"
        }
      ],
      "id": "cucumber:host:hosts/to-annotate",
      "owner": "cucumber:policy:hosts",
      "permissions": [
        {
          "policy": "cucumber:policy:root",
          "privilege": "read",
          "role": "cucumber:user:bob"
        },
        {
          "policy": "cucumber:policy:root",
          "privilege": "read",
          "role": "cucumber:user:alice"
        }
      ],
      "policy": "cucumber:policy:hosts",
      "restricted_to": [

      ]
    }
    """

  @negative
  @acceptance
  Scenario: User with create privilege can NOT add new annotations with PATCH
    When I login as "alice"
    And I save my place in the log file
    Then I PATCH "/policies/cucumber/policy/hosts" with body:
    """
    - !host
      id: to-annotate
      annotations:
        description: Success
    """
    Then the HTTP response status code is 403
    And The following appears in the log after my savepoint:
    """
    CONJ00006E 'cucumber:user:alice' does not have 'update' privilege on cucumber:policy:hosts
    """

  @negative
  @acceptance
  Scenario: User with create privilege can NOT update existing annotations with PUT
    When I login as "alice"
    And I save my place in the log file
    Then I PUT "/policies/cucumber/policy/hosts" with body:
    """
    - !host
      id: annotated
      annotations:
        description: Success
    """
    Then the HTTP response status code is 403
    And The following appears in the log after my savepoint:
    """
    CONJ00006E 'cucumber:user:alice' does not have 'update' privilege on cucumber:policy:hosts
    """

  @negative
  @acceptance
  Scenario: User with create privilege CAN NOT update existing annotations with POST, but policy loads successfully
    When I login as "alice"
    Then I successfully POST "/policies/cucumber/policy/hosts" with body:
    """
    - !host
      id: annotated
      annotations:
        description: Success
    """
    And I successfully GET "/resources/cucumber/host/hosts%2Fannotated"
    Then the JSON should be:
    """
    {
      "annotations": [
        {
          "name": "description",
          "policy": "cucumber:policy:hosts",
          "value": "Already annotated"
        }
      ],
      "id": "cucumber:host:hosts/annotated",
      "owner": "cucumber:policy:hosts",
      "permissions": [
        {
          "policy": "cucumber:policy:root",
          "privilege": "read",
          "role": "cucumber:user:bob"
        },
        {
          "policy": "cucumber:policy:root",
          "privilege": "read",
          "role": "cucumber:user:alice"
        }
      ],
      "policy": "cucumber:policy:hosts",
      "restricted_to": [

      ]
    }
    """

  @negative
  @acceptance
  Scenario: User with create privilege can NOT update existing annotations with PATCH
    When I login as "alice"
    And I save my place in the log file
    Then I PATCH "/policies/cucumber/policy/hosts" with body:
    """
    - !host
      id: annotated
      annotations:
        description: Success
    """
    Then the HTTP response status code is 403
    And The following appears in the log after my savepoint:
    """
    CONJ00006E 'cucumber:user:alice' does not have 'update' privilege on cucumber:policy:hosts
    """

  @smoke
  @acceptance
  Scenario: User with update privilege can add new annotations with PUT
    When I login as "bob"
    Then I successfully PUT "/policies/cucumber/policy/hosts" with body:
    """
    - !host
      id: to-annotate
      annotations:
        description: Success
    """
    And I successfully GET "/resources/cucumber/host/hosts%2Fto-annotate"
    Then the JSON should be:
    """
    {
      "annotations": [
        {
          "name": "description",
          "policy": "cucumber:policy:hosts",
          "value": "Success"
        }
      ],
      "id": "cucumber:host:hosts/to-annotate",
      "owner": "cucumber:policy:hosts",
      "permissions": [
        {
          "policy": "cucumber:policy:root",
          "privilege": "read",
          "role": "cucumber:user:bob"
        },
        {
          "policy": "cucumber:policy:root",
          "privilege": "read",
          "role": "cucumber:user:alice"
        }
      ],
      "policy": "cucumber:policy:hosts",
      "restricted_to": [

      ]
    }
    """

  @negative
  @acceptance
  Scenario: User with update privilege can NOT add new annotations with POST
    When I login as "bob"
    And I save my place in the log file
    Then I POST "/policies/cucumber/policy/hosts" with body:
    """
    - !host
      id: to-annotate
      annotations:
        description: Success
    """
    Then the HTTP response status code is 403
    And The following appears in the log after my savepoint:
    """
    CONJ00006E 'cucumber:user:bob' does not have 'create' privilege on cucumber:policy:hosts
    """

  @smoke
  @acceptance
  Scenario: User with update privilege can add new annotations with PATCH
    When I login as "bob"
    Then I successfully PATCH "/policies/cucumber/policy/hosts" with body:
    """
    - !host
      id: to-annotate
      annotations:
        description: Success
    """
    And I successfully GET "/resources/cucumber/host/hosts%2Fto-annotate"
    Then the JSON should be:
    """
    {
      "annotations": [
        {
          "name": "description",
          "policy": "cucumber:policy:hosts",
          "value": "Success"
        }
      ],
      "id": "cucumber:host:hosts/to-annotate",
      "owner": "cucumber:policy:hosts",
      "permissions": [
        {
          "policy": "cucumber:policy:root",
          "privilege": "read",
          "role": "cucumber:user:bob"
        },
        {
          "policy": "cucumber:policy:root",
          "privilege": "read",
          "role": "cucumber:user:alice"
        }
      ],
      "policy": "cucumber:policy:hosts",
      "restricted_to": [

      ]
    }
    """

  @smoke
  @acceptance
  Scenario: User with update privilege can update existing annotations with PUT
    When I login as "bob"
    Then I successfully PUT "/policies/cucumber/policy/hosts" with body:
    """
    - !host
      id: annotated
      annotations:
        description: Success
    """
    And I successfully GET "/resources/cucumber/host/hosts%2Fannotated"
    Then the JSON should be:
    """
    {
      "annotations": [
        {
          "name": "description",
          "policy": "cucumber:policy:hosts",
          "value": "Success"
        }
      ],
      "id": "cucumber:host:hosts/annotated",
      "owner": "cucumber:policy:hosts",
      "permissions": [
        {
          "policy": "cucumber:policy:root",
          "privilege": "read",
          "role": "cucumber:user:bob"
        },
        {
          "policy": "cucumber:policy:root",
          "privilege": "read",
          "role": "cucumber:user:alice"
        }
      ],
      "policy": "cucumber:policy:hosts",
      "restricted_to": [

      ]
    }
    """

  @negative
  @acceptance
  Scenario: User with update privilege can NOT update existing annotations with POST
    When I login as "bob"
    And I save my place in the log file
    Then I POST "/policies/cucumber/policy/hosts" with body:
    """
    - !host
      id: annotated
      annotations:
        description: Success
    """
    Then the HTTP response status code is 403
    And The following appears in the log after my savepoint:
    """
    CONJ00006E 'cucumber:user:bob' does not have 'create' privilege on cucumber:policy:hosts
    """

  @smoke
  @acceptance
  Scenario: User with update privilege can update existing annotations with PATCH
    When I login as "bob"
    Then I successfully PATCH "/policies/cucumber/policy/hosts" with body:
    """
    - !host
      id: annotated
      annotations:
        description: Success
    """
    And I successfully GET "/resources/cucumber/host/hosts%2Fannotated"
    Then the JSON should be:
    """
    {
      "annotations": [
        {
          "name": "description",
          "policy": "cucumber:policy:hosts",
          "value": "Success"
        }
      ],
      "id": "cucumber:host:hosts/annotated",
      "owner": "cucumber:policy:hosts",
      "permissions": [
        {
          "policy": "cucumber:policy:root",
          "privilege": "read",
          "role": "cucumber:user:bob"
        },
        {
          "policy": "cucumber:policy:root",
          "privilege": "read",
          "role": "cucumber:user:alice"
        }
      ],
      "policy": "cucumber:policy:hosts",
      "restricted_to": [

      ]
    }
    """
