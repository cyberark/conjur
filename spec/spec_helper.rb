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

def with_background_process(cmd, &block)
  puts("Running: #{cmd}")
  Open3.popen2e(
    cmd,
    pgroup: true
  ) do |stdin, stdout_and_err, wait_thr|
    # We don't need to interact with stdin for the background process,
    # so close that stream immediately.
    stdin.close_write

    # Read the output of the background process in a thread to run
    # the given block in parallel.
    out_reader = Thread.new do
      output = StringIO.new

      loop do
        ready = IO.select(
          [stdout_and_err], # Watch for reading
          [], # Not watching any files for writing
          [], # Not watching any files for exceptions
          # When the background process is killed, it doesn't end the
          # the output stream, so we need a timeout here to recognize the
          # stream has closed:
          1 # 1 second timeout
        )

        # If the stream has closed, break the read loop.
        break if stdout_and_err.closed?

        # If we've reached the end of the stream, break the read loop.
        break if stdout_and_err.eof?

        # If this was the result of a IO#select timeout, enter the select
        # loop again.
        next unless ready

        # Read the next available output on the stream
        output << stdout_and_err.read_nonblock(1024)
      end

      # Return the collected output as the result of the read thread
      output.string
    end

    # Call the given block
    block.call

    # Kill the background process and any children processes
    pgid = Process.getpgid(wait_thr.pid)
    Process.kill("-TERM", pgid) if wait_thr.alive?

    # Wait for the background process to end
    wait_thr.value

    # Close the output thread
    stdout_and_err.close

    # Wait for the result from the reader thread
    out_reader.value
  end
end

def conjur_server_dir
  # Get the path to conjurctl
  conjurctl_path = `readlink -f $(which conjurctl)`

  # Navigate from its directory (/bin) to the root Conjur server directory
  Pathname.new(File.join(File.dirname(conjurctl_path), '..')).cleanpath
end


require 'stringio'
