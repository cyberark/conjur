Feature: Host Factories can be managed through policies.

  Scenario: Create a host factory on a layer.
    
    The layer is added to the "host_factory_layers" field.
    The "host_factory_tokens" field is empty.

    Given a policy:
    """
    - !layer
      id: myapp
    
    - !host-factory
      id: myapp
      layers: [ !layer myapp ]
    """
    Then there is a host_factory resource "myapp"
    And I show the host_factory "myapp"
    Then the "host_factory_layers" should be:
    """
    [
      "cucumber:layer:myapp"
    ]
    """
    And the "host_factory_tokens" should be:
    """
    [
    ]
    """

  Scenario: Layers which are not under the management of the policy cannot
    be added to the host factory.
    
    Given I try to load the policy:
    """
    - !layer default
    
    - !policy
      id: myapp
      body:
      - !host-factory
        layers: [ !layer ../default ]
    """
    Then the error code is "not_found"
    And the error message is "Layer 'myapp/../default' not found in account 'cucumber'"
