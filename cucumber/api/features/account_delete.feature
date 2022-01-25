@api
Feature: Delete an account

  Accounts can be deleted through the API.

  Background:
    Given I create a new user "privileged" in account "!"
    And I permit role "!:user:privileged" to "execute" resource "!:webservice:accounts"
    And I permit role "!:user:privileged" to "read" resource "!:webservice:accounts"
    And I permit role "!:user:privileged" to "update" resource "!:webservice:accounts"

    And I create a new user "unprivileged" in account "!"
    And I permit role "!:user:unprivileged" to "execute" resource "!:webservice:accounts"
    And I permit role "!:user:unprivileged" to "read" resource "!:webservice:accounts"

    And I login as "!:user:privileged"
    Then I successfully POST "/accounts" with body:
    """
    id=new.account
    """

  @smoke
  Scenario: DELETE /accounts/:id to delete an account.

    "update" privilege on "!:webservice:accounts" is required.
    
    Given I login as "!:user:privileged"
    Then I successfully DELETE "/accounts/new.account"
    And I successfully GET "/accounts"
    And the JSON should not include "new.account"

  @acceptance
  Scenario: DELETE /accounts requires "update" privilege.

    Without "update" privilege the request is forbidden.

    Given I login as "!:user:unprivileged"
    When I DELETE "/accounts/new.account"
    Then the HTTP response status code is 403
    And the result is empty

  @acceptance
  Scenario: Root policy can be reloaded after DELETE

    Given I login as "new.account:user:admin"
    And I successfully PUT "/policies/new.account/policy/root" with body:
    """
    - !variable var
    """

    Then I login as "!:user:privileged"
    And I successfully DELETE "/accounts/new.account"
    When I successfully POST "/accounts" with body:
    """
    id=new.account
    """

    When I login as "new.account:user:admin"
    Then I successfully PUT "/policies/new.account/policy/root" with body:
    """
    - !variable var
    """
