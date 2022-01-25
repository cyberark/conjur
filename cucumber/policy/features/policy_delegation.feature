@policy
Feature: Policies can be organized into hierarchies with specific update permissions.

  @acceptance
  Scenario: Define a root policy with sub-policies
  
    Given I load a policy:
    """
    - !policy
      id: teams
      body:
      - !group frontend

    - !policy
      id: prod
      body:
      - !policy
        id: frontend
        body: []

    - !user bob

    - !grant
      role: !group teams/frontend
      member: !user bob

    - !permit
      resource: !policy prod/frontend
      privilege: [ read, update ]
      role: !group teams/frontend
    """
    And I log in as user "bob"
    And I replace the "prod/frontend" policy with:
    """
    - &variables
      - !variable ssl/cert
      - !variable ssl/private_key

    - !layer

    - !permit
      role: !layer
      privileges: [ read, execute ]
      resources: *variables

    - !host 01

    - !grant
      role: !layer
      member: !host 01
    """
    When I log in as user "admin"
    Then I can add a secret to variable resource "prod/frontend/ssl/cert"
    And I log in as host "prod/frontend/01"
    Then I can fetch a secret from variable resource "prod/frontend/ssl/cert"
