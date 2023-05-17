# frozen_string_literal: true

# This allows to you reference some global variables such as `$?` using less
# cryptic names like `$CHILD_STATUS`
require 'English'

require 'stringio'

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

# Please note, VCR is configured to only run when the `:vcr` arguement
# is passed to the RSpec block. Calling VCR with `VCR.use_cassette` will
# not work.
require 'vcr'
VCR.configure do |config|
  config.hook_into(:webmock)
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    decode_compressed_response: true
  }
end

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.around do |example|
    if example.metadata[:vcr]
      example.run
    else
      VCR.turned_off { example.run }
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
  slosilo = Slosilo[token_id(account, "user")] ||= Slosilo::Key.new
  bearer_token = slosilo.issue_jwt(sub: user)
  "Token token=\"#{Base64.strict_encode64(bearer_token.to_json)}\""
end

def with_background_process(cmd, &block)
  puts("Running: #{cmd}")
  Open3.popen2e(
    cmd,
    pgroup: true
  ) do |stdin, stdout_and_err, wait_thr|
    output = StringIO.new
    # Read the output of the background process in a thread to run
    # the given block in parallel.
    out_reader = Thread.new do
      Thread.current.abort_on_exception = true

      loop do
        break if stdout_and_err.closed? || stdout_and_err.eof?
        next unless stdout_and_err.wait_readable(1)

        output << stdout_and_err.read_nonblock(1024)
      rescue IOError
        break
      end
    end

    block.call

    out_reader.kill
    pgid = Process.getpgid(wait_thr.pid)
    Process.kill("-TERM", pgid) if wait_thr.alive?

    # Wait for the background process to end
    wait_thr.value

    output.string
  end
end

def conjur_server_dir
  # Get the path to conjurctl
  conjurctl_path = `readlink -f $(which conjurctl)`

  # Navigate from its directory (/bin) to the root Conjur server directory
  Pathname.new(File.join(File.dirname(conjurctl_path), '..')).cleanpath
end

# Allows running a block of test code as another user.
# For example, to run a block without root privileges.
def as_user(user, &block)
  prev = Process.uid
  u = Etc.getpwnam(user)
  Process.uid = Process.euid = u.uid
  block.call
ensure
  Process.uid = Process.euid = prev
end

def token_auth_header(role:, account: 'rspec', is_user: true)
  slosilo_key = is_user ? token_key(account, "user") : token_key(account, "host")
  bearer_token = slosilo_key.signed_token(role.login)
  base64_token = Base64.strict_encode64(bearer_token.to_json)

  { 'HTTP_AUTHORIZATION' => "Token token=\"#{base64_token}\"" }
end
