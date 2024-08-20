# frozen_string_literal: true

# This allows to you reference some global variables such as `$?` using less
# cryptic names like `$CHILD_STATUS`
require 'English'

require 'stringio'

require 'simplecov'

require 'aws-sdk-sns'

require 'aws-sdk-sqs'

SimpleCov.command_name("SimpleCov #{rand(1000000)}")
SimpleCov.merge_timeout(7200)
SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
ENV["CONJUR_LOG_LEVEL"] ||= 'debug'
ENV['TENANT_PROFILES'] = 'us-east-1'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each {|f| require f}

ENV['CONJUR_ACCOUNT'] = 'rspec'
ENV['TENANT_ID'] = "mytenant"
ENV['TENANT_REGION'] = "us-east-1"

ENV.delete('CONJUR_ADMIN_PASSWORD')

$LOAD_PATH << '../app/domain'

# Add conjur-cli load path to the specs, since these source files are
# not under the default load paths.
$LOAD_PATH << './bin/conjur-cli'


# Please note, VCR is configured to only run when the `:vcr` arguement
# is passed to the RSpec block. Calling VCR with `VCR.use_cassette` will
# not work.
require 'vcr'
require 'webmock/rspec'
VCR.configure do |config|
  config.hook_into(:webmock)
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    decode_compressed_response: true
  }
  config.allow_http_connections_when_no_cassette = true
end

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    Rails.cache.clear
  end

  config.around(:each) do |example|
    Rails.cache.clear
    puts("Running #{example.metadata[:location]}")
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

def create_sqs_queue

  WebMock.allow_net_connect!
  sqs = Aws::SQS::Client.new
  response = sqs.create_queue(queue_name: 'MyTestQueue')
  queue_url = response.queue_url
  ENV['QUEUE_URL'] = queue_url
  sqs.get_queue_attributes(queue_url: queue_url, attribute_names: ['QueueArn']).attributes['QueueArn']
end

def delete_sqs_queue
  sqs = Aws::SQS::Client.new
  sqs.delete_queue(queue_url: ENV['QUEUE_URL'])
end

def create_sns_topic
  WebMock.allow_net_connect!
  sns = Aws::SNS::Client.new
  response = sns.create_topic(
    name: "MyFifoTopic.fifo",
    attributes: {
      'FifoTopic' => 'true',
      'ContentBasedDeduplication' => 'true'
    }
  )
  Rails.application.config.conjur_config.conjur_pubsub_sns_topic = response.topic_arn
  Rails.application.config.conjur_config.conjur_pubsub_iam_role =  "arn:aws:iam::0000000000000:role/developer"
end

def delete_sns_topic
  sns = Aws::SNS::Client.new
  sns.delete_topic(topic_arn: Rails.application.config.conjur_config.conjur_pubsub_sns_topic)
  WebMock.disallow_net_connect!
end

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

def v2_api_header
  { 'Accept' => "application/x.secretsmgr.v2+json" }
end

def create_host(host_id, owner, api_key_annotation=true)
  host_role = Role.create(role_id: host_id)
  host_role.tap do |role|
    resource = Resource.create(resource_id: host_id, owner: owner)
    # If needed add the annotation to create api key
    add_api_key_annotation(resource, role, api_key_annotation)
    Credentials[role: role] || Credentials.new(role: role).save(raise_on_save_failure: true)
  end
  host_role
end

def create_host_without_apikey(host_id, owner)
  create_host(host_id, owner, false)
end

def add_api_key_annotation(resource, role, api_key_annotation)
  # If needed add the annotation to create api key
  if api_key_annotation
    role.annotations <<
      Annotation.create(resource: resource,
                        name: "authn/api-key",
                        value: "true")
  end
end

def verify_audit_message(audit_message)
  message_found = false
  expect(log_object).to have_received(:log).at_least(:once) do |log_message|
    if log_message.to_s == audit_message
      message_found = true
    end
  end
  expect(message_found).to eq(true)
end

def get_field_value(hash_list, field_to_get, field_to_check, condition_value)
  hash_list.each do |entry|
    if entry[field_to_check] == condition_value
      return entry[field_to_get]
    end
  end
  nil  # Return nil if no match is found
end
