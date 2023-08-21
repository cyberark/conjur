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

# so that we can require relative to the project root
$LOAD_PATH.unshift(Dir.pwd)
require 'config/environment'

ENV['RAILS_ENV'] ||= 'test'
ENV['CONJUR_LOG_LEVEL'] ||= 'debug'

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || "http://conjur#{ENV['TEST_ENV_NUMBER']}"
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'
