require 'cucumber/rails'
require 'rack/test'
require 'json_spec/cucumber'

#ENV['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
#ENV['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"

#api_string = "CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"
#ENV['CONJUR_AUTHN_API_KEY'] = ENV[api_string]

def app
  Rails.application
end
