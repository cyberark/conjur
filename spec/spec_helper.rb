# frozen_string_literal: true

require 'simplecov'
require 'digest'
require 'openssl'

SimpleCov.command_name "SimpleCov #{rand(1000000)}"
SimpleCov.merge_timeout 7200
SimpleCov.start

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
ENV["CONJUR_LOG_LEVEL"] ||= 'debug'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

ENV['CONJUR_ACCOUNT'] = 'rspec'
ENV.delete('CONJUR_ADMIN_PASSWORD')

$LOAD_PATH << '../app/domain'

RSpec.configure do |config|
  config.before(:all) do
    OpenSSL.fips_mode = true
    ActiveSupport::Digest.hash_digest_class = OpenSSL::Digest::SHA1.new
    Sprockets::DigestUtils.module_eval do
      def digest_class
        OpenSSL::Digest::SHA256
      end
    end

    new_sprockets_config = {}
    Sprockets.config.each do |key, val|
      new_sprockets_config[key] = val
    end
    new_sprockets_config[:digest_class] = OpenSSL::Digest::SHA256
    Sprockets.config = new_sprockets_config.freeze

    OpenIDConnect::Discovery::Provider::Config::Resource.module_eval do
      def cache_key
        sha256 = Digest::SHA256.hexdigest host
        "swd:resource:opneid-conf:#{sha256}"
      end
    end
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.order = "random"
  config.filter_run_excluding performance: true
  config.infer_spec_type_from_file_location!
  config.filter_run_when_matching :focus
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
  exit_status = ($?).exitstatus

  # Grep exit codes:
  # 0   - match
  # 1   - no match
  # 2   - file not found
  # 127 - cmd not found, ie, grep missing
  raise "grep wasn't found" if exit_status == 127
  raise "log file not found" if exit_status == 2
  raise "unexpected grep error" if exit_status > 1

  # Remaining possibilities are 0 and 1, secret found or not found.
  secret_found = exit_status == 0
  secret_found
end


require 'stringio'
