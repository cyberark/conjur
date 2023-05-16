# frozen_string_literal: true

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
$LOAD_PATH.unshift(Dir.pwd)
require 'config/environment'

ENV['RAILS_ENV'] ||= 'test'
ENV['CONJUR_LOG_LEVEL'] ||= 'debug'


Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || "http://conjur#{ENV['TEST_ENV_NUMBER']}"
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'
