Feature: RBAC privileges control whether a role can update and/or fetch a secret.

  Background:
    Given I create a new user "bob"
    And I create a new resource
    And I permit user "bob" to "read" it
    And I create 1 secret values

  Scenario: Fetching a secret as an unauthorized user results in a 403 error.

    Given I login as "bob"
    When I GET "/secrets/cucumber/:resource_kind/:resource_id"
    Then the HTTP response status code is 403

  Scenario: Updating a secret as an unauthorized user results in a 403 error.

    Given I login as "bob"
    When I POST "/secrets/cucumber/:resource_kind/:resource_id" with parameters:
    """
    v-1
    """
    Then the HTTP response status code is 403

  Scenario: A foreign role can be granted permission to fetch a secret.

    The `execute` privilege can be granted to any role to allow it to fetch a secret.

    Given I permit user "bob" to "execute" it
    And I login as "bob"
    Then I can GET "/secrets/cucumber/:resource_kind/:resource_id"

  Scenario: A foreign role can be granted permission to update a secret.

    The `update` privilege can be granted to any role to allow it to update a secret.
 
    Given I permit user "bob" to "update" it
    When I login as "bob"
    Then I can POST "/secrets/cucumber/:resource_kind/:resource_id" with parameters:
    """
    v-1
    """
