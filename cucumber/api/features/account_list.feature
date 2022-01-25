@api
Feature: List accounts

  The list of accounts, excluding the "!" special account, is available through the
  API. 

  Background:
    Given I create a new user "admin" in account "!"
    And I permit role "!:user:admin" to "execute" resource "!:webservice:accounts"
    And I login as "!:user:admin"
    Then I successfully POST "/accounts" with body:
    """
    id=new-account
    """

  @smoke
  Scenario: GET /accounts to list accounts.

    "read" privilege on "!:webservice:accounts" is required.

    The response is a JSON array of account names.
    Given I create a new user "auditor" in account "!"
    And I permit role "!:user:auditor" to "read" resource "!:webservice:accounts"
    And I login as "!:user:auditor"
    Then I successfully GET "/accounts"
    And the JSON should include "new-account"
    And the JSON should not include "!"

  @acceptance 
  @logged-in-admin
  Scenario: GET /accounts requires "read" privilege.

    Without "read" privilege the request is forbidden.

    When I GET "/accounts"
    Then the HTTP response status code is 403
    And the result is empty
