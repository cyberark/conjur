@api
@logged-in
Feature: Create a host factory token.

  Background:
    Given I create a new user "alice"
    And I create a host factory for layer "the-layer"

  @negative @acceptance
  Scenario: A host factory is invisible without some permission on it
    Given I login as "alice"

    When I POST "/host_factory_tokens?host_factory=cucumber:host_factory:the-layer-factory&expiration=2050-12-31" with in-body params
    Then the HTTP response status code is 404

  @negative @acceptance
  Scenario: Unauthorized users cannot create host factory tokens.
    Given I permit user "alice" to "read" it
    And I login as "alice"
    When I POST "/host_factory_tokens?host_factory=cucumber:host_factory:the-layer-factory&expiration=2050-12-31"
    Then the HTTP response status code is 403

  @smoke
  Scenario: A host factory token can be created by specifying an expiration time.
    Given I permit user "alice" to "execute" it
    And I login as "alice"
    # TODO: It appears we are posting this as query string only to have
    # cucumber convert it back into a hash which it then sends as an ordinary
    # body POST.  This serves no purpose afaict.
    When I successfully POST "/host_factory_tokens?host_factory=cucumber:host_factory:the-layer-factory&expiration=2050-12-31" with in-body params
    Then our JSON should be:
    """
    [
      {
        "cidr": [],
        "expiration": "2050-12-31T00:00:00Z",
        "token": "@host_factory_token@"
      }
    ]
    """

  @acceptance
  Scenario: A host factory token can be created by specifying an expiration time and CIDR.
    Given I permit user "alice" to "execute" it
    And I login as "alice"
    When I successfully POST "/host_factory_tokens?host_factory=cucumber:host_factory:the-layer-factory&expiration=2050-12-31&cidr[]=123.234.0.0/16&cidr[]=222.222.222.0/24" with in-body params
    Then our JSON should be:
    """
    [
      {
        "cidr": [
          "123.234.0.0/16",
          "222.222.222.0/24"
        ],
        "expiration": "2050-12-31T00:00:00Z",
        "token": "@host_factory_token@"
      }
    ]
    """

  @negative @acceptance
  Scenario: A host factory token cannot be created with invalid CIDR
    Given I permit user "alice" to "execute" it
    And I login as "alice"
    When I POST "/host_factory_tokens?host_factory=cucumber:host_factory:the-layer-factory&expiration=2050-12-31&cidr[]=123.234.0.0/16&cidr[]=1.895.abc.0/32" with in-body params
    Then the HTTP response status code is 422
    And there is an error
    And the error message is "Invalid IP address or CIDR range '1.895.abc.0/32'"
