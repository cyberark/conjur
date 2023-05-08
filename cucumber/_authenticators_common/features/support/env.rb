# frozen_string_literal: true

parallel_cuke_vars = Hash.new
parallel_cuke_vars['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
parallel_cuke_vars['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"
parallel_cuke_vars['CONJUR_AUTHN_API_KEY'] = ENV["CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"]

parallel_cuke_vars.each do |key, value|
  ENV[key] = value
end

$LOAD_PATH.unshift(Dir.pwd)
require 'config/environment'

require 'rest-client'
require 'aruba'
require 'aruba/cucumber'
require 'conjur-api'
require 'json_spec/cucumber'

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || "http://conjur#{ENV['TEST_ENV_NUMBER']}"
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'
