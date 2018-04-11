Feature: Working with host factory tokens.

  Background:
    Given I run the code:
    """
    $conjur.load_policy 'root', <<-POLICY
    - !policy
      id: myapp
      body:
      - !layer

      - !host-factory
        layers: [ !layer ]
    POLICY
    @expiration = (DateTime.now + 1.hour).change(sec: 0)
    @host_factory = $conjur.resource('cucumber:host_factory:myapp')
    """

  @wip
  Scenario: Create a new host factory token.
    When I run the code:
    """
    @token = @host_factory.create_token @expiration
    """
    Then I can run the code:
    """
    expect(@token).to be_instance_of(Conjur::HostFactoryToken)
    expect(@token.token).to be_instance_of(String)
    expiration = @token.expiration
    expiration = expiration.change(sec: 0)
    expect(expiration).to eq(@expiration)
    """
    And I can run the code:
    """
    expect(@host_factory.tokens).to eq([@token])
    """

  Scenario: Create multiple new host factory tokens.
    When I run the code:
    """
    @host_factory.create_tokens @expiration, count: 2
    """
    Then the JSON should have 2 items

  Scenario: Revoke a host factory token using the token object.
    When I run the code:
    """
    @token = @host_factory.create_token @expiration
    """
    Then I can run the code:
    """
    @token.revoke
    """

  Scenario: Revoke a host factory token using the API.
    When I run the code:
    """
    @token = @host_factory.create_token @expiration
    """
    Then I can run the code:
    """
    $conjur.revoke_host_factory_token @token.token
    """
