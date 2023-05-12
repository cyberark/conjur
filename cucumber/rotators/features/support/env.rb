# frozen_string_literal: true

# so that we can require relative to the project root
$LOAD_PATH.unshift(Dir.pwd)
require 'config/environment'

ENV['RAILS_ENV'] ||= 'test'
ENV['CONJUR_LOG_LEVEL'] ||= 'debug'

ENV['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
ENV['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"

api_string = "CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"
ENV['CONJUR_AUTHN_API_KEY'] = ENV[api_string]
ENV['KEYCLOAK_REDIRECT_URI'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}:3000/authn-oidc/keycloak2/cucumber/authenticate"

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || "http://conjur#{ENV['TEST_ENV_NUMBER']}"
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'
