# frozen_string_literal: true

#api_string = "CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"
#h = Hash.new
#h['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
#h['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"
#h['CONJUR_AUTHN_API_KEY'] = ENV[api_string]

#h.each do |key, value|
  ##ENV[key] || ENV[key] = value
  #if ENV[key].nil? || ENV[key].empty?
    #ENV[key] = value
    #puts "#{File.dirname(__FILE__)}/#{File.basename(__FILE__)}"
    #puts "SET #{key}: #{value}"
  #end
#end

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
