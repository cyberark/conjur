# frozen_string_literal: true

# Similar to appliance.rb but removes configuration for aggregated logging and
# audit database, which are not used in a containerized follower.

# Since this file gets injected into the Conjur project, these dependency paths
# will be correct by the time this file gets run.
load File.expand_path('production.rb', __dir__)
require 'rack/remember_uuid'
require 'logger/formatter/conjur_formatter'

def filter_logs(log)
  (log.name == "AuthenticateController" ) || (log.name == "SecretsController" ) ||
  !( log.name.end_with?("Controller") && log.message.include?("Completed"))
end

Rails.application.configure do

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true


  # Must log to STDOUT to ensure Rails output shows up when retrieving logs from
  # the pod container using the kubectl / oc CLI tool. Must also used logger
  # with tags due to a hidden dependency in the k8s authenticator logic.
  config.logger = ActiveSupport::TaggedLogging.new(
      Logger.new(STDOUT, formatter: ConjurFormatter.new)
  )

  # Setting a new logger appears to overwrite any logger configuration that was
  # already applied so we must set this field again even though it was already
  # set in production.rb.
  config.log_level = :warn #ENV['CONJUR_LOG_LEVEL'] || :info

  SemanticLogger.default_level = :warn
  config.rails_semantic_logger.started    = false
  config.rails_semantic_logger.processing = false
  config.rails_semantic_logger.rendered   = false
  config.rails_semantic_logger.level = :warn
  config.rails_semantic_logger.filter = Proc.new {
    |log| filter_logs(log)
  }
  config.colorize_logging = false

  SemanticLogger.add_appender(io: $stdout, filter: config.rails_semantic_logger.filter)

  config.middleware.use Rack::RememberUuid
  config.audit_socket = '/run/conjur/audit.socket'

end
