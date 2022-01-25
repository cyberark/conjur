@api
Feature: Create a new account

  Conjur supports multiple accounts in a single database. Each account is a
  separate "tenant" with its own set of data.

  Importantly, each account also uses its own token-signing key, so that tokens
  created by one account won't be accepted by a different account.

  Accounts are managed through a standard REST interface.  The "accounts" routes
  are authorized via privileges on the resource "!:webservice:accounts".

  @smoke
  Scenario: POST /accounts to create a new account.

    "execute" privilege on "!:webservice:accounts" is required.

    The response is JSON which contains:

    1. **id** The account id.
    2. **api_key** The API key of the account "admin" user.

    # Note: "!" is the default account
    Given I create a new user "admin" in account "!"
    And I permit role "!:user:admin" to "execute" resource "!:webservice:accounts"
    And I login as "!:user:admin"
    Then I successfully POST "/accounts" with body:
    """
    id=new-account
    """
    And the JSON should have "id"
    And the JSON should have "api_key"

  @negative @acceptance
  @logged-in-admin
  Scenario: POST /accounts requires "execute" privilege.

    Without "execute" privilege the request is forbidden.

    When I POST "/accounts" with body:
    """
    {
      id: new-account
    }
    """
    Then the HTTP response status code is 403
    And the result is empty

  @negative @acceptance
  Scenario: An account cannot be created if it already exists.

    Given I create a new user "admin" in account "!"
    And I permit role "!:user:admin" to "execute" resource "!:webservice:accounts"
    And I login as "!:user:admin"
    Then I successfully POST "/accounts" with body:
    """
    id=new-account
    """
    And I POST "/accounts" with body:
    """
    id=new-account
    """
    Then the HTTP response status code is 409
    And the JSON should be:
    """
    {
      "error": {
        "code": "conflict",
        "details": {
          "code": "conflict",
          "message": "new-account",
          "target": "id"
        },
        "message": "account \"new-account\" already exists",
        "target": "account"
      }
    }
    """

  @acceptance
  Scenario: An account can be created with an owner

    Given I create a new user "admin" in account "!"
    And I permit role "!:user:admin" to "execute" resource "!:webservice:accounts"
    And I login as "!:user:admin"
    Then I successfully POST "/accounts" with body:
    """
    id=new-account&owner_id=!:user:admin
    """
    And the JSON should have "id"
    And the JSON should have "api_key"

  @acceptance
  Scenario: An account can be created with a '.' in its name

    Given I create a new user "admin" in account "!"
    And I permit role "!:user:admin" to "execute" resource "!:webservice:accounts"
    And I login as "!:user:admin"
    Then I successfully POST "/accounts" with body:
    """
    id=new_account@example.com
    """
    And I can authenticate with the admin API key for the account "new_account@example.com"

  @negative @acceptance
  Scenario: Creating account with : or space in the name fails

    Given I create a new user "admin" in account "!"
    And I permit role "!:user:admin" to "execute" resource "!:webservice:accounts"
    And I login as "!:user:admin"
    Then I POST "/accounts" with body:
    """
    id=test:bad
    """
    Then the HTTP response status code is 422
    And the JSON should be:
    """
    {
      "error": {
        "code": "argument_error",
        "message": "account name \"test:bad\" contains invalid characters (:)"
      }
    }
    """

    When I POST "/accounts" with body:
    """
    id=test+bad
    """
    Then the HTTP response status code is 422
    And the JSON should be:
    """
    {
      "error": {
        "code": "argument_error",
        "message": "account name \"test bad\" contains invalid characters ( )"
      }
    }
    """

  @smoke
  @create_account
  Scenario: Creating account with predefined password and login with it
    Given I create an account with the name "demo" and the password "MySecretP,@SS1()!" using conjurctl
    Then I can GET "/authn/demo/login" with username "admin" and password "MySecretP,@SS1()!"
