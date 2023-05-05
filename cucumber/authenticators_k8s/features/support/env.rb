require 'cucumber/rails'
require 'rack/test'
require 'json_spec/cucumber'

ENV['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
ENV['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"

def app
  Rails.application
end
