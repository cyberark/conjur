Feature: Create a host using a host factory token.

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
    @token = @host_factory.create_token @expiration
    """

  Scenario: I can create a host from the token
    When I run the code:
    """
    Conjur::API.host_factory_create_host(@token.token, "app-01")
    """
    Then the JSON should have "id"
    And the JSON should have "permissions"
    And the JSON should have "owner"
    And the JSON should have "api_key"
