# frozen_string_literal: true

# Similar to appliance.rb but removes configuration for aggregated logging and
# audit database, which are not used in a containerized follower.

# Since this file gets injected into the Conjur project, these dependency paths
# will be correct by the time this file gets run.
load File.expand_path('production.rb', __dir__)
require 'rack/remember_uuid'
require 'logger/formatter/conjur_formatter'

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
  config.log_level = :info #ENV['CONJUR_LOG_LEVEL'] || :info

  SemanticLogger.default_level = :info
  config.rails_semantic_logger.started    = true
  config.rails_semantic_logger.processing = true
  config.rails_semantic_logger.rendered   = true

  SemanticLogger.add_appender(io: $stdout)

  config.middleware.use Rack::RememberUuid
  config.audit_socket = '/run/conjur/audit.socket'

end
