@api
Feature: Updating policies

  Policy updates can be performed in any of three modes: PUT, PATCH, and POST.
  The permission required depends on the mode.

  Background:
    Given I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !user alice
    - !user bob
    - !user carol
    - !user sam

    - !policy
      id: dev
      owner: !user alice
      body:
      - !policy
        id: db

    - !permit
      resource: !policy dev/db
      privilege: [ create, update ]
      role: !user bob

    - !permit
      resource: !policy dev/db
      privilege: [ create ]
      role: !user carol
    """

  @acceptance
  Scenario: a policy is invisible without some permission on it
    When I login as "sam"
    And I POST "/policies/cucumber/policy/dev/db" with body:
    """
    - !variable a
    """
    Then the HTTP response status code is 404

  @acceptance
  Scenario: `create` privilege is sufficient to add records to a policy via POST.
    When I login as "alice"
    Then I successfully POST "/policies/cucumber/policy/dev/db" with body:
    """
    - !variable a
    """
