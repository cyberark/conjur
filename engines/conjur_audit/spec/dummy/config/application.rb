# frozen_string_literal: true

require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "sequel_rails"

Bundler.require(*Rails.groups)
require "conjur_audit"

module Dummy
  # Dummy application used for tests
  class Application < Rails::Application
    configure do
      config.sequel.schema_dump = false
    end
  end
end
