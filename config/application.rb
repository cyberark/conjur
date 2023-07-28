# frozen_string_literal: true


require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
#require "active_model/railtie"
#require "active_job/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
#require "action_mailer/railtie"
#require "action_view/railtie"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Workaround for debify not being able to use embedded gems.
$LOAD_PATH.push(File.expand_path("../../engines/conjur_audit/lib", __FILE__))
require 'conjur_audit'

# Must require because lib folder hasn't been loaded yet
require './lib/conjur/conjur_config'

module Conjur
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Replace md5 with sha for FIPS compliance
    config.active_support.hash_digest_class = ::Digest::SHA1

    config.autoload_paths << Rails.root.join('lib')

    config.encoding = "utf-8"
    config.active_support.escape_html_entities_in_json = true

    # Sets all the blank Environment Variables to nil. This ensures that nil
    # checks are sufficient to verify the usage of an environment variable.
    ENV.each_pair do |(k, v)|
      ENV[k] = nil if v =~ /^\s*$/ # is all whitespace
    end

    # Allows us to use a config file that doesn't group values by Rails env.
    config.anyway_config.future.unwrap_known_environments = true

    config.anyway_config.default_config_path = "/etc/conjur/config"
  end
end
