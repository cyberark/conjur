Feature: Validating specific privileges

  Background:
    Given I create a new resource
    And a new user "bob"
    And I permit user "bob" to "fry" it

  @logged-in
  Scenario: I confirm that the role can perform the granted action
    Then I can GET "/roles/:account/user/bob@:user_namespace" with parameters:
    """
    check: true
    resource: "@resource_kind@:@resource_id@"
    privilege: fry
    """

  @logged-in
  Scenario: I confirm that the role cannot perform ungranted actions
    When I GET "/roles/:account/user/bob@:user_namespace" with parameters:
    """
    check: true
    resource: "@resource_kind@:@resource_id@"
    privilege: freeze
    """
    Then it's not found

  Scenario: The new role can confirm that it may perform the granted action
    When I login as "bob"
    Then I can GET "/resources/:account/:resource_kind/:resource_id" with parameters:
    """
    check: true
    privilege: fry
    """
