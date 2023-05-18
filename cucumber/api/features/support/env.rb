# frozen_string_literal: true

ENV['CONJUR_ACCOUNT'] = 'cucumber'
ENV['RAILS_ENV'] ||= 'test'
ENV['CONJUR_LOG_LEVEL'] ||= 'debug'

puts "******************************************"
ENV.each do |key, value|
  puts "key: #{key} value: #{value}"
end
puts "******************************************"

api_string = "CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"
h = Hash.new
h['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
h['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"
h['CONJUR_AUTHN_API_KEY'] = ENV[api_string]

h.each do |key, value|
  #ENV[key] || ENV[key] = value
  if ENV[key].nil? || ENV[key].empty?
    ENV[key] = value
    puts "#{File.dirname(__FILE__)}/#{File.basename(__FILE__)}"
    puts "SET #{key}: #{value}"
  end
end

# so that we can require relative to the project root
$LOAD_PATH.unshift(File.expand_path('../../../..', __dir__))
require 'config/environment'

require 'json_spec/cucumber'
require_relative 'utils'
require 'tmpdir'
require 'securerandom'

# This line is here to support running these tests outside a container,
# per Rafal's request.  It could be deleted were it not for that.
ENV['CONJUR_APPLIANCE_URL'] ||= Utils.start_local_server

Slosilo["authn:cucumber"] ||= Slosilo::Key.new

JsonSpec.excluded_keys = %w[created_at updated_at]
