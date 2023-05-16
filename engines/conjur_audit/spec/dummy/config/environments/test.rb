# frozen_string_literal: true

if ENV['CONJUR_APPLIANCE_URL'].nil? || ENV['CONJUR_APPLIANCE_URL'].empty?
  ENV['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
  puts "SET CONJUR_APPLIANCE_URL #{File.dirname(__FILE__)}/#{File.basename(__FILE__)}"
else
  puts "NOT EMPTY CONJUR_APPLIANCE_URL"
end
if ENV['DATABASE_URL'].nil? || ENV['DATABASE_URL'].empty?
  ENV['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"
  puts "SET DATABASE_URL #{File.dirname(__FILE__)}/#{File.basename(__FILE__)}"
else
  puts "NOT EMPTY DATABASE_URL"
end
if ENV['CONJUR_AUTHN_API_KEY'].nil? || ENV['CONJUR_AUTHN_API_KEY'].empty?
  api_string = "CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"
  ENV['CONJUR_AUTHN_API_KEY'] = ENV[api_string]
  puts "SET CONJUR_AUTHN_API_KEY #{File.dirname(__FILE__)}/#{File.basename(__FILE__)}"
else
  puts "NOT EMPTY CONJUR_AUTHN_API_KEY"
end

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = false
  config.action_controller.allow_forgery_protection = false
  config.active_support.test_order = :random
  config.active_support.deprecation = :stderr
end
