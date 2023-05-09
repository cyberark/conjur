# frozen_string_literal: true

ENV['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
ENV['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"

api_string = "CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"
ENV['CONJUR_AUTHN_API_KEY'] = ENV[api_string]

$LOAD_PATH.unshift(Dir.pwd)
require 'config/environment'

require 'rest-client'
require 'aruba'
require 'aruba/cucumber'
require 'conjur-api'
require 'json_spec/cucumber'

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || "http://conjur#{ENV['TEST_ENV_NUMBER']}"
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'
