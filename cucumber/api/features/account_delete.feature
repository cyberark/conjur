Feature: Delete an account

  Accounts can be deleted through the API.

  Background:
    Given I create a new user "admin" in account "!"
    And I permit role "!:user:admin" to "execute" resource "!:webservice:accounts"
    And I login as "!:user:admin"
    Then I successfully POST "/accounts" with body:
    """
    id=new-account
    """

  Scenario: DELETE /accounts/:id to delete an account.

    "update" privilege on "!:webservice:accounts" is required.

    And I permit role "!:user:admin" to "read" resource "!:webservice:accounts"
    And I permit role "!:user:admin" to "update" resource "!:webservice:accounts"
    Then I successfully DELETE "/accounts/new-account"
    And I successfully GET "/accounts"
    And the JSON should not include "new-account"

  Scenario: DELETE /accounts requires "update" privilege.

    Without "update" privilege the request is forbidden.

    When I DELETE "/accounts/new-account"
    Then the HTTP response status code is 403
    And the result is empty
