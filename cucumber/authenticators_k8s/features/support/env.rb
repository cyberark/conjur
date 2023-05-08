require 'cucumber/rails'
require 'rack/test'
require 'json_spec/cucumber'

parallel_cuke_vars = Hash.new
parallel_cuke_vars['CONJUR_APPLIANCE_URL'] = "http://nginx#{ENV['TEST_ENV_NUMBER']}"
parallel_cuke_vars['DATABASE_URL'] = "postgres://postgres@postgres#{ENV['TEST_ENV_NUMBER']}:5432/postgres"
parallel_cuke_vars['CONJUR_AUTHN_API_KEY'] = ENV["CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"]

parallel_cuke_vars.each do |key, value|
  ENV[key] = value
end

def app
  Rails.application
end
