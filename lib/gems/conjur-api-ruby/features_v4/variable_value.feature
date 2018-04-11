Feature: Work with Variable values.
  Background:
    Given I run the code:
    """
    @variable = $conjur.resource("cucumber:variable:db-password")
    @variable_2 = $conjur.resource("cucumber:variable:ssh-key")
    """

  Scenario: Add a value, retrieve the variable metadata and the value.
    Given I run the code:
    """
    @initial_count = @variable.version_count
    @variable.add_value 'value-0'
    """
    When I run the code:
    """
    expect(@variable.version_count).to eq(@initial_count + 1)
    """
    And I run the code:
    """
    @variable.value
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
      "db-password": "value-0",
      "ssh-key": "value-2"
    }
    """
