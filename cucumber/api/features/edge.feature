@api
Feature: Fetching secrets from edge endpoint

  Background:
    Given I create a new user "some_user"
    And I have host "some_host"
    And I am the super-user
    And I successfully PUT "/policies/cucumber/policy/root" with body:
    """
    - !policy
      id: edge
      body:
        - !group edge-admins
        - !policy
            id: edge-EDGE_IDENTIFIER
            body:
            - !host
              id: edge-host-EDGE_IDENTIFIER
              annotations:
                authn/api-key: true

    - !grant
      role: !group edge/edge-admins
      members:
        - !host edge/edge-EDGE_IDENTIFIER/edge-host-EDGE_IDENTIFIER
    """
    And I log out


  @acceptance
  Scenario: Fetching secrets with edge host return 200

    Given I login as "host/edge/edge-EDGE_IDENTIFIER/edge-host-EDGE_IDENTIFIER"
    When I GET "/edge/secrets/cucumber"
    Then the HTTP response status code is 200

  @negative @acceptance
  Scenario: Fetching secrets with non edge host return 403

    Given I login as "some_user"
    When I GET "/edge/secrets/cucumber"
    Then the HTTP response status code is 403
    Given I login as "host/some_host"
    When I GET "/edge/secrets/cucumber"
    Then the HTTP response status code is 403

  @acceptance
  Scenario: Fetching hosts with edge host return 200

    Given I login as "host/edge/edge-EDGE_IDENTIFIER/edge-host-EDGE_IDENTIFIER"
    When I GET "/edge/hosts/cucumber"
    Then the HTTP response status code is 200

  @negative @acceptance
  Scenario: Fetching hosts with non edge host return 403

    Given I login as "some_user"
    When I GET "/edge/hosts/cucumber"
    Then the HTTP response status code is 403
    Given I login as "host/some_host"
    When I GET "/edge/hosts/cucumber"
    Then the HTTP response status code is 403
