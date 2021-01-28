# frozen_string_literal: true

load File.expand_path '../production.rb', __FILE__
require 'syslog/logger'

Rails.application.configure do
  config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new('conjur-possum'))
  config.log_level = ENV['CONJUR_LOG_LEVEL'] || :info
  config.audit_socket = '/run/conjur/audit.socket'
end
