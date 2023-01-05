# frozen_string_literal: true

Before do
  # Create a new Scenario Context to use for sharing
  # data between scenario steps.
  @scenario_context = Utilities::ScenarioContext.new
end

After do
  # Reset scenario context
  @scenario_context.reset!
end
