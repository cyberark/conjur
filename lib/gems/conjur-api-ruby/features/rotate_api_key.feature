Feature: Rotate the API key.

  Scenario: Logged-in user can rotate the API key.
    When I run the code:
    """
    Conjur::API.rotate_api_key 'admin', $api_key
    """
    Then I can run the code:
    """
    $api_key = @result.strip
    $conjur = Conjur::API.new_from_key $username, @result
    $conjur.token
    """
