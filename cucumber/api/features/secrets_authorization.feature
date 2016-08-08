Feature: Fetching secrets

  Background:
    Given a resource
    And a new user "bob"
    And I create 1 secret values

  Scenario: Fetching a secret as an unauthorized user results in a 403 error.
    Given I login as "bob"
    When I GET "/secrets/:account/:resource_kind/:resource_id"
    Then it's forbidden

  Scenario: Updating a secret as an unauthorized user results in a 403 error.
    Given I login as "bob"
    When I POST "/secrets/:account/:resource_kind/:resource_id" with parameters:
    """
    v-1
    """
    Then it's forbidden

  Scenario: A foreign user can be granted permission to fetch a secret.
    Given I permit user "bob" to "execute" it
    And I login as "bob"
    Then I can GET "/secrets/:account/:resource_kind/:resource_id"

  Scenario: A foreign user can be granted permission to update a secret.
    Given I permit user "bob" to "update" it
    When I login as "bob"
    Then I can POST "/secrets/:account/:resource_kind/:resource_id" with parameters:
    """
    v-1
    """

  Scenario: Acting as a foreign role is not allowed.
    Given a new user "alice"
    And I login as "bob"
    When I GET "/secrets/:account/:resource_kind/:resource_id?acting_as=@account@:user:alice@@user_namespace@"
    Then it's forbidden

  Scenario: Acting as a non-existant role is not allowed.
    Given I login as "bob"
    When I GET "/secrets/:account/:resource_kind/:resource_id?acting_as=@account@:user:alice@@user_namespace@"
    Then it's forbidden

  Scenario: Acting as a foreign role which I have been granted is allowed.
    Given a new user "alice"
    And I permit user "alice" to "execute" it
    And I grant user "alice" to user "bob"
    When I login as "bob"
    Then I can GET "/secrets/:account/:resource_kind/:resource_id?acting_as=@account@:user:alice@@user_namespace@"
