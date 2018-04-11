Feature: Display Host object fields.

  Background:
    Given a new host

  Scenario: API key of a newly created host is available and valid.
    Then I run the code:
    """
    expect(@host.exists?).to be(true)
    expect(@host.api_key).to be
    Conjur::API.new_from_key(@host.login, @host.api_key).token
    """

  Scenario: API key of a a host can be rotated.
    Then I run the code:
    """
    host = Conjur::API.new_from_key(@host.login, @host.api_key).resource(@host.id)
    api_key = host.rotate_api_key
    Conjur::API.new_from_key(@host.login, api_key).token
    """
