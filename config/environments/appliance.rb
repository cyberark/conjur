# frozen_string_literal: true

load File.expand_path '../production.rb', __FILE__
require 'rack/remember_uuid'
require './config/conjur_log_formatter'

Rails.application.configure do
  config.log_level = :info
  config.log_formatter = ConjurLogFormatter.new
  config.middleware.use Rack::RememberUuid
  config.audit_socket = '/run/conjur/audit.socket'
  config.audit_database ||= 'postgres://:5433/audit'
end
