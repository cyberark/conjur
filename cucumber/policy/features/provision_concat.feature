Feature: Variables can be provisioned by values in the policy load context

  Scenario: A policy with a concat provisioned variable
    Given a policy document:
    """
    - !variable
      id: initial_a
      annotations:
        provision/provisioner: context
        provision/context/parameter: a_value
    
    - !variable
      id: initial_b
      annotations:
        provision/provisioner: context
        provision/context/parameter: b_value

    - !variable
      id: ab_concat
      annotations:
        provision/provisioner: concat
        provision/concat/1/variable: initial_a
        provision/concat/3/literal: c
        provision/concat/2/variable: initial_b
        
    """
    And the policy context:
    | a_value | a |
    | b_value | b |
    When I load the policy into 'root'
    Then I can fetch a secret from variable resource "ab_concat"
    And the result is:
    """
    abc
    """

  Scenario: Concatenated value with newline
    Given a policy document:
    """
    - !variable
      id: newline_concat
      annotations:
        provision/provisioner: concat
        provision/concat/with: "\n"
        provision/concat/1/literal: a
        provision/concat/2/literal: b
        
    """
    When I load the policy into 'root'
    Then I can fetch a secret from variable resource "newline_concat"
    And the result is:
    """
    a
    b
    """
