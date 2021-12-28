# frozen_string_literal: true

load File.expand_path('../production.rb', __FILE__)
require 'rack/remember_uuid'
require 'syslog/logger'

Rails.application.configure do
  config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new('conjur-possum'))
  config.log_level = ENV['CONJUR_LOG_LEVEL'] || :info
  config.middleware.use(Rack::RememberUuid)
  #config.audit_socket = '/run/conjur/audit.socket'
  config.audit_database ||= 'postgres://:5433/audit'
end
