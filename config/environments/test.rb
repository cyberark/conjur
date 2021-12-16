# frozen_string_literal: true

require 'logger/formatter/conjur_formatter'
require 'test/audit_sink'

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
