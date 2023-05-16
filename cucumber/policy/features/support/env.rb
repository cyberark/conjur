# frozen_string_literal: true

require 'aruba'
require 'aruba/cucumber'
require 'conjur-api'
require 'rest-client'

if ENV['CONJUR_APPLIANCE_URL'].nil? || ENV['CONJUR_APPLIANCE_URL'].empty?
  ENV['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
  puts "SET CONJUR_APPLIANCE_URL #{File.dirname(__FILE__)}/#{File.basename(__FILE__)}"
else
  puts "NOT EMPTY CONJUR_APPLIANCE_URL"
end
if ENV['DATABASE_URL'].nil? || ENV['DATABASE_URL'].empty?
  ENV['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"
  puts "SET DATABASE_URL #{File.dirname(__FILE__)}/#{File.basename(__FILE__)}"
else
  puts "NOT EMPTY DATABASE_URL"
end
if ENV['CONJUR_AUTHN_API_KEY'].nil? || ENV['CONJUR_AUTHN_API_KEY'].empty?
  api_string = "CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"
  ENV['CONJUR_AUTHN_API_KEY'] = ENV[api_string]
  puts "SET CONJUR_AUTHN_API_KEY #{File.dirname(__FILE__)}/#{File.basename(__FILE__)}"
else
  puts "NOT EMPTY CONJUR_AUTHN_API_KEY"
end

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || "http://conjur#{ENV['TEST_ENV_NUMBER']}"
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'

# This is needed to run the cucumber --profile policy successfully
# otherwise it fails due to the way root_loader sets its admin password
ENV.delete('CONJUR_ADMIN_PASSWORD')

# so that we can require relative to the project root
$LOAD_PATH.unshift(File.expand_path('../../../..', __dir__))
require 'config/environment'
