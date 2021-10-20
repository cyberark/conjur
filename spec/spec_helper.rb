# frozen_string_literal: true

# This allows to you reference some global variables such as `$?` using less 
# cryptic names like `$CHILD_STATUS`
require 'English'

require 'simplecov'

SimpleCov.command_name("SimpleCov #{rand(1000000)}")
SimpleCov.merge_timeout(7200)
SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
  print_error_status=false
  #SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter
  #SimpleCov.formatter SimpleCov::Formatter::HTMLFormatter
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
ENV["CONJUR_LOG_LEVEL"] ||= 'debug'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each {|f| require f}

ENV['CONJUR_ACCOUNT'] = 'rspec'
ENV.delete('CONJUR_ADMIN_PASSWORD')

$LOAD_PATH << '../app/domain'

# Add conjur-cli load path to the specs, since these source files are
# not under the default load paths.
$LOAD_PATH << './bin/conjur-cli'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.order = "random"
  config.filter_run_excluding(performance: true)
  config.infer_spec_type_from_file_location!
  config.filter_run_when_matching(:focus)
end

# We want full-length error messages since RSpec has a pretty small
# limit for those when they're printed
RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = 999

def secret_logged?(secret)
  log_file = './log/test.log'

  # We use grep because doing this pure ruby is slow for large log files.
  #
  # We use backticks because we want the exit code for detailed error messages.
  `grep --quiet '#{secret}' '#{log_file}'`
  exit_status = $CHILD_STATUS.exitstatus

  # Grep exit codes:
  # 0   - match
  # 1   - no match
  # 2   - file not found
  # 127 - cmd not found, ie, grep missing
  raise "grep wasn't found" if exit_status == 127
  raise "log file not found" if exit_status == 2
  raise "unexpected grep error" if exit_status > 1

  # Remaining possibilities are 0 and 1, secret found or not found.
  exit_status == 0
  
end

# Creates valid access token for the given username.
# :reek:UtilityFunction
def access_token_for(user, account: 'rspec')
  # Configure Slosilo to produce valid access tokens
  slosilo = Slosilo["authn:#{account}"] ||= Slosilo::Key.new
  bearer_token = slosilo.issue_jwt(sub: user)
  "Token token=\"#{Base64.strict_encode64(bearer_token.to_json)}\""
end

require 'stringio'
