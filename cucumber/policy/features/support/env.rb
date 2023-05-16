# frozen_string_literal: true

require 'aruba'
require 'aruba/cucumber'
require 'conjur-api'
require 'rest-client'

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

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || "http://conjur#{ENV['TEST_ENV_NUMBER']}"
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'

# This is needed to run the cucumber --profile policy successfully
# otherwise it fails due to the way root_loader sets its admin password
ENV.delete('CONJUR_ADMIN_PASSWORD')

# so that we can require relative to the project root
$LOAD_PATH.unshift(File.expand_path('../../../..', __dir__))
require 'config/environment'
