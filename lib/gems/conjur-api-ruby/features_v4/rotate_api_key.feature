Feature: Rotate the API key.

  Scenario: Logged-in user can rotate the API key.
    When I run the code:
    """
    $conjur.role('cucumber:user:alice').rotate_api_key
    """
    Then I can run the code:
    """
    @api_key = @result.strip
    @conjur = Conjur::API.new_from_key 'alice', @api_key
    @conjur.token
    """
