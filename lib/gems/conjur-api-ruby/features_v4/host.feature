Feature: Display Host object fields.

  Background:
    Given a new host

  Scenario: API key of a newly created host is available and valid.
    Then I run the code:
    """
    expect(@host.exists?).to be(true)
    expect(@host.api_key).to be
    """

  Scenario: API key of a a host can be rotated.
    Then I run the code:
    """
    api_key = @host.rotate_api_key
    Conjur::API.new_from_key("host/#{@host.id.identifier}", api_key).token
    """
