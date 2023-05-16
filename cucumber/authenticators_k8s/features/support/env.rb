require 'cucumber/rails'
require 'rack/test'
require 'json_spec/cucumber'


api_string = "CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"
h = Hash.new
h['CONJUR_APPLIANCE_URL'] = "https://nginx#{ENV['TEST_ENV_NUMBER']}"
h['DATABASE_URL'] = "postgres://postgres@postgres#{ENV['TEST_ENV_NUMBER']}:5432/postgres"
h['CONJUR_AUTHN_API_KEY'] = ENV[api_string]

h.each do |key, value|
  #ENV[key] || ENV[key] = value
  if ENV[key].nil? || ENV[key].empty?
    ENV[key] = value
    puts "#{File.dirname(__FILE__)}/#{File.basename(__FILE__)}"
    puts "SET #{key}: #{value}"
  end
end

def app
  Rails.application
end
