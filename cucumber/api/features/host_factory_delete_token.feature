@api
@logged-in
Feature: Delete (revoke) a host factory token.

Background:
  Given I create a new user "alice"
  And I create a host factory for layer "the-layer"
  And I create a host factory token

  @negative @acceptance
  Scenario: Unauthorized users cannot delete host factory tokens.
    When I try to DELETE "/host_factory_tokens/@host_factory_token@"
    Then the HTTP response status code is 404

    Given I permit user "alice" to "execute" it
    When I login as "alice"
    And I try to DELETE "/host_factory_tokens/@host_factory_token@"
    Then the HTTP response status code is 403

  @smoke
  Scenario: "delete" privilege on the host factory allows a user to delete
    tokens.

    Given I permit user "alice" to "update" it
    When I login as "alice"
    Then I do DELETE "/host_factory_tokens/@host_factory_token@"

  @negative @acceptance
  Scenario: Once the token has been deleted, subsequent attempts return 404 Not Found.

    Given I permit user "alice" to "update" it
    When I login as "alice"
    And I do DELETE "/host_factory_tokens/@host_factory_token@"
    And I try to DELETE "/host_factory_tokens/@host_factory_token@"
    Then the HTTP response status code is 404
