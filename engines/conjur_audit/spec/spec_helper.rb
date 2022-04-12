# frozen_string_literal: true

require 'simplecov'
SimpleCov.command_name("SimpleCov #{rand(1000000)}")
SimpleCov.merge_timeout(1800)
SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
end

require 'db_helper'

RSpec.configure do |config|
  config.expect_with(:rspec) do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with(:rspec) do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching(:focus)
  config.example_status_persistence_file_path = "/tmp/examples.txt"
  config.disable_monkey_patching!

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.profile_examples = 10

  config.order = :random
  Kernel.srand(config.seed)

  config.include_context("database setup")
end
