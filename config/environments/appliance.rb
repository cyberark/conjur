load File.expand_path '../production.rb', __FILE__

Rails.application.configure do
  config.log_level = :info
  config.middleware.use Audit::RememberUuid
  config.audit_socket = '/run/conjur/audit.socket'
  config.audit_database ||= 'postgres://:5433/audit'
end
