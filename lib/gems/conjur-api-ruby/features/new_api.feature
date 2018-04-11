Feature: Constructing a new API object.
  Background:
    Given a new host

  Scenario: From API key.
    Then I run the code:
    """
    api = Conjur::API.new_from_key "host/#{@host_id}", @host_api_key
    expect(api.token).to be_instance_of(Hash)
    expect(api.resource("cucumber:host:#{@host_id}")).to exist
    """

  Scenario: From access token.
    Given I run the code:
    """
    @token = Conjur::API.new_from_key("host/#{@host_id}", @host_api_key).token
    """
    Then I run the code:
    """
    api = Conjur::API.new_from_token @token
    expect(api.resource("cucumber:host:#{@host_id}")).to exist
    """

  Scenario: From access token file.
    Given I run the code:
    """
    token = Conjur::API.new_from_key("host/#{@host_id}", @host_api_key).token
    @temp_file = Tempfile.new("token.json")
    @temp_file.write(token.to_json)
    @temp_file.flush
    """
    Then I run the code:
    """
    api = Conjur::API.new_from_token_file @temp_file.path
    expect(api.resource("cucumber:host:#{@host_id}")).to exist
    """
