# frozen_string_literal: true

LOG_LEVELS = ['debug', 'info', 'warn', 'error', 'fatal', 'unknown']
LOG_LEVEL_ERROR = "Environment variable 'CONJUR_LOG_LEVEL' must be a valid Rails log level: #{LOG_LEVELS.inspect}"

def assert_valid_conjur_log_level
  log_level_env = ENV['CONJUR_LOG_LEVEL']
  if log_level_env
    raise LOG_LEVEL_ERROR unless LOG_LEVELS.include? log_level_env
  end
end

# Load the Rails application.
require File.expand_path('../application', __FILE__)

assert_valid_conjur_log_level

# Initialize the Rails application.
Rails.application.initialize!
