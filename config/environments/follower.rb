# frozen_string_literal: true

# Similar to appliance.rb but removes configuration for aggregated logging and
# audit database, which are not used in a containerized follower.

load File.expand_path '../production.rb', __FILE__
require 'rack/remember_uuid'

Rails.application.configure do
  config.log_level = ENV['CONJUR_LOG_LEVEL'] || :info
  config.middleware.use Rack::RememberUuid
  config.audit_socket = '/run/conjur/audit.socket'
  config.audit_database = 'postgres://:5433/audit'
end
