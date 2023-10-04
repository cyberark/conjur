require 'cucumber/rails'
require 'rack/test'
require 'json_spec/cucumber'

parallel_cuke_vars = {}
parallel_cuke_vars['CONJUR_APPLIANCE_URL'] = "http://nginx#{ENV['TEST_ENV_NUMBER']}"
parallel_cuke_vars['DATABASE_URL'] = "postgres://postgres@postgres#{ENV['TEST_ENV_NUMBER']}:5432/postgres"
parallel_cuke_vars['CONJUR_AUTHN_API_KEY'] = ENV["CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"]

parallel_cuke_vars.each do |key, value|
  if ENV[key].nil? || ENV[key].empty?
    ENV[key] = value
  end
end

def app
  Rails.application
end
