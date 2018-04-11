Feature: When co-located with the Conjur server, the API can use the authn-local service to authenticate.

  Scenario: authn-local can be used to obtain an access token.
    When I run the code:
    """
    Conjur::API.authenticate_local "alice"
    """
    Then the JSON should have "data"

  Scenario: Conjur API supports construction from authn-local.
    When I run the code:
    """
    @api = Conjur::API.new_from_authn_local "alice"
    @api.token
    """
    Then the JSON should have "data"

  Scenario: Conjur API will automatically refresh the token.
    When I run the code:
    """
    @api = Conjur::API.new_from_authn_local "alice"
    @api.token
    @api.force_token_refresh
    @api.token
    """
    Then the JSON should have "data"
    And the JSON at "data" should be "alice"
