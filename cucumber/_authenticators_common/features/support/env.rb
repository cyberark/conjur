# frozen_string_literal: true

parallel_cuke_vars = {}
parallel_cuke_vars['CONJUR_APPLIANCE_URL'] = ENV.fetch('CONJUR_APPLIANCE_URL', "http://conjur#{ENV['TEST_ENV_NUMBER']}")
parallel_cuke_vars['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"
parallel_cuke_vars['CONJUR_AUTHN_API_KEY'] = ENV["CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"]

parallel_cuke_vars.each do |key, value|
  if ENV[key].nil? || ENV[key].empty?
    ENV[key] = value
  end
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
