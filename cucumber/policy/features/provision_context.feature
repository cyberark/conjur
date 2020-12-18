Feature: Variables can be provisioned by values in the policy load context

  Scenario: A policy with a context provisioned variable
    Given a policy document:
    """
    - !variable
      id: provisioned/context-secret
      annotations:
        provision/provisioner: context
        provision/context/parameter: value
      
    """
    And the policy context:
    | value | my secret value |
    When I load the policy into 'root'
    Then I can fetch a secret from variable resource "provisioned/context-secret"
    And the result is:
    """
    my secret value
    """
