load File.expand_path '../production.rb', __FILE__
require 'rack/remember_uuid'

Rails.application.configure do
  config.log_level = :info
  config.middleware.use Rack::RememberUuid
  config.audit_socket = '/run/conjur/audit.socket'
  config.audit_database ||= 'postgres://:5433/audit'
end
