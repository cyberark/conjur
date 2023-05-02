CUKES_LOG_DURATION = 'true'

CUKES_IMAGE_TAG = 'Example'
Scenario = Struct.new(:id, :cukes_image_tag)

# TODO: figure out how to put this in the ccontainer log
def log(str)
  STDERR.puts(str)
end

Before do |scenario|
  # Record the start time for the scenario and the first step
  @scenario_start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  @step_start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  # tag = REUSE_CONTAINERS ? 'reusable' : Random.hex(8)
  tag = Random.hex(8)
  @scenario = Scenario.new(tag, CUKES_IMAGE_TAG)
end

AfterStep do |_result, step|
  # After each step of a cucumber scenario, inject the completed step name
  # into each container log using syslog. This makes it easier to correlate
  # the steps with their outcomes in the container logs.
  log("AFTER CUCUMBER STEP: #{step.text}")

  if CUKES_LOG_DURATION
    # Write the duration of the cuke step to the runner log
    step_end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    step_duration = step_end_time - @step_start_time
    log(sprintf("Step duration (%s): %0.2fs", step.text, step_duration))

    # Reset the timer for the next step
    @step_start_time = step_end_time
  end
end

After do |scenario|
  if CUKES_LOG_DURATION
    # Write the duration of the cuke scenario to the runner log
    scenario_end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    scenario_duration = scenario_end_time - @scenario_start_time
    log(sprintf("Scenario duration (%s): %0.2fs", scenario.name, scenario_duration))
  end
end
