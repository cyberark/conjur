Feature: Working with host factory tokens.

  Background:
    Given I run the code:
    """
    @expiration = (DateTime.now + 1.hour).change(sec: 0)
    """


  Scenario: Create a new host factory token.
    When I run the code:
    """
    @token = $host_factory.create_token(@expiration)
    """
    Then I can run the code:
    """
    expect(@token).to be_instance_of(Conjur::HostFactoryToken)
    expect(@token.token).to be_instance_of(String)
    expiration = @token.expiration
    expiration = expiration.change(sec: 0)
    expect(expiration).to eq(@expiration)
    """

  Scenario: Create multiple new host factory tokens.
    When I run the code:
    """
    $host_factory.create_tokens @expiration, count: 2
    """
    Then the JSON should have 2 items

  Scenario: Revoke a host factory token using the token object.
    When I run the code:
    """
    @token = $host_factory.create_token @expiration
    """
    Then I can run the code:
    """
    @token.revoke
    """

  Scenario: Revoke a host factory token using the API.
    When I run the code:
    """
    @token = $host_factory.create_token @expiration
    """
    Then I can run the code:
    """
    $conjur.revoke_host_factory_token @token.token
    """
