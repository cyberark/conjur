# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
ENV['CONJUR_LOG_LEVEL'] ||= 'debug'
require File.expand_path('../dummy/config/environment', __FILE__)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'spec_helper'
require 'rspec/rails'

RSpec.shared_context("engine routes") do
  routes { ConjurAudit::Engine.routes }
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include_context("engine routes", type: :controller)
  config.include(ConjurAudit::Engine.routes.url_helpers)
end
