Feature: Load a policy.

  Scenario: Policy can be loaded into a policy id.
    Then I can run the code:
    """
    policy = <<-POLICY
    - !group security_admin

    - !policy
      id: myapp
      body:
      - !layer

      - !host-factory
        layers: [ !layer ]

    - !host app-01

    - !grant
      role: !layer myapp
      member: !host app-01
    POLICY

    $conjur.load_policy 'root', policy
    """

  Scenario: The policy load reports the API keys of created roles.
    Then I can run the code:
    """
    $conjur.load_policy 'root', <<-POLICY
    - !host app-#{random_hex}
    POLICY
    """
    Then the JSON should have "version"
    And the JSON should have "created_roles"
    And the JSON at "created_roles" should have 1 item

  Scenario: Policy contents can be replaced using POLICY_METHOD_PUT.
    Given I run the code:
    """
    $conjur.load_policy 'root', <<-POLICY
    - !group developers
    - !group operations
    POLICY
    """
    And I run the code:
    """
    $conjur.load_policy 'root', <<-POLICY, method: Conjur::API::POLICY_METHOD_PUT
    --- []
    POLICY
    """
    And I run the code:
    """
    $conjur.resources.map(&:id)
    """
    Then the JSON should be:
    """
    [
      "cucumber:policy:root"
    ]
    """
