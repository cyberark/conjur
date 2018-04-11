Feature: Work with Variable values.

  Background:
    Given I run the code:
    """
    @variable_id = "password"
    $conjur.load_policy 'root', <<-POLICY
    - !variable #{@variable_id}
    - !variable #{@variable_id}-2
    POLICY
    @variable = $conjur.resource("cucumber:variable:#{@variable_id}")
    @variable_2 = $conjur.resource("cucumber:variable:#{@variable_id}-2")
    """

  Scenario: Add a value, retrieve the variable metadata and the value.
    When I run the code:
    """
    @initial_count = @variable.version_count
    @variable.add_value 'value-0'
    """
    And I run the code:
    """
    expect(@variable.version_count).to eq(@initial_count + 1)
    """
    And I run the code:
    """
    @variable.value(@variable.version_count)
    """
    Then the result should be "value-0"

  Scenario: Retrieve a historical value.
    Given I run the code:
    """
    @variable.add_value 'value-0'
    @variable.add_value 'value-1'
    @variable.add_value 'value-2'
    """
    When I run the code:
    """
    @variable.value(@variable.version_count - 2)
    """
    Then the result should be "value-0"

  Scenario: Retrieve multiple values in a batch
    Given I run the code:
    """
    @variable.add_value 'value-0'
    @variable_2.add_value 'value-2'
    """
    When I run the code:
    """
    $conjur.variable_values([ @variable, @variable_2 ].map(&:id))
    """
    Then the JSON should be:
    """
    {
      "cucumber:variable:password": "value-0",
      "cucumber:variable:password-2": "value-2"
    }
    """
