# frozen_string_literal: true

require 'logger/formatter/conjur_formatter'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = true

  # Whitelist conjur hostname for tests
  # For more information, refer to:
  # https://guides.rubyonrails.org/configuring.html#actiondispatch-hostauthorization
  config.hosts << "conjur"

  # eager_load needed to make authentication work without the hacky
  # loading code...
  #
  config.public_file_server.enabled = true
  config.eager_load = true
  # config.assets.digest = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = ENV['CONJUR_LOG_LEVEL'] || :debug
  config.log_formatter = ConjurFormatter.new

  # Don't care if the mailer can't send.
  # config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
end
