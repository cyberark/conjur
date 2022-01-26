@policy
Feature: Host Factories can be managed through policies.

  @smoke
  Scenario: Create a host factory on a layer.

    The layer is added to the "layers" field.
    The "tokens" field is empty.

    Given I load a policy:
      """
      - !layer
        id: myapp

      - !host-factory
        id: myapp
        layers: [ !layer myapp ]
      """
    Then there is a host_factory resource "myapp"
    And I show the host_factory "myapp"
    Then the "layers" should be:
      """
      [
        "cucumber:layer:myapp"
      ]
      """
    And the "tokens" should be:
      """
      []
      """

  @acceptance
  Scenario: Layers which are not under the management of the policy cannot
    be added to the host factory.

    Given I try to load a policy with an unresolvable reference:
      """
      - !layer default

      - !policy
        id: myapp
        body:
        - !host-factory
          layers: [ !layer ../default ]
      """
    Then there's an error
    And the error code is "not_found"
    And the error message is "Layer 'myapp/../default' not found in account 'cucumber'"

  @acceptance
  Scenario: The host factory can be defined in a separate policy load event from the creation
    of the layer.

    Given I load a policy:
      """
      - !layer
        id: myapp
      """
    And I extend the policy with:
      """
      - !host-factory
        id: myapp
        layers: [ !layer myapp ]
      """
    Then there is a host_factory resource "myapp"
    And I show the host_factory "myapp"
    Then the "layers" should be:
      """
      [
        "cucumber:layer:myapp"
      ]
      """

  @acceptance
  Scenario: Load a Host Factory with no layers
    Given I load a policy:
      """
      - !policy
        id: another-app
        body:
        - !policy
          id: hosts
          annotations:
            description: Layer & Host Factory for machines that can read secrets
          body:
          - !layer
          - !host-factory
      """
    Then there's an error
    And the error code is "policy_invalid"
    And the error message is "Host factory 'another-app/hosts' does not include any layers"
