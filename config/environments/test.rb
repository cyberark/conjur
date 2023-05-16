# frozen_string_literal: true

require 'logger/formatter/conjur_formatter'
require 'test/audit_sink'

# Might only need to place the ENV vars in this file instead of throughout the cucumber env.rb files
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
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # We're setting this to true so that test environment matches the prod environment.
  # Since we've had bugs related to rails loading.
  #
  config.eager_load = true

  # Configure static file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = false
  config.static_cache_control = 'public, max-age=3600'

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  # config.action_mailer.delivery_method = :test

  # Randomize the order test cases are executed.
  config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = ENV['CONJUR_LOG_LEVEL'] || :debug
  config.log_formatter = ConjurFormatter.new

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # TODO: figure out how to make it work in a spring environment
  config.audit_socket = Test::AuditSink.instance.address

  # We don't want to cache TRUSTED_PROXIES for tests so that these may
  # be modified for different test scenarios.
  config.conjur_disable_trusted_proxies_cache = true
end
