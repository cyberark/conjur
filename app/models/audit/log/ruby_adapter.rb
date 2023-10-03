# Provides a convenient interface for logging _events_.
#
# We use the adapter pattern to give our audit logger an interface
# customized to its purpose, allowing us to write:
#
#   Audit.logger.log(some_event)
#
# instead of (as required by ruby's default logger):
#
#   Audit.logger.log(event.severity, event, ::Audit::Event.progname)
#
# wherever we use it.
#
# The correct adapter, which depends on the environment, will be configured
# automatically by the audit_socket.rb initializer.
module Audit
  module Log
    class RubyAdapter
      def initialize(ruby_logger)
        @ruby_logger = ruby_logger
      end

      # We don't want "event" to have knowledge of the logger's API, so the
      # FeatureEnvy suggestion (caused by the repetition of "event" below) is
      # incorrect.  Obeying it would be to do exactly what we're trying to
      # avoid.
      # :reek:FeatureEnvy
      def log(event)
        # NOTE: With the Rails logger, this `to_s` is actually unnecessary: The
        # "ActiveSupport::TaggedLogging::Formatter#call" method implicitly
        # invokes to_s when it calls:
        #
        #       super(severity, timestamp, progname, "#{tags_text}#{msg}")
        #
        # However, we do not want an implicit dependency on the Rails logger,
        # even though we happen to be using it now.  Our only dependency should
        # be on the _interface_ defined by Ruby's standard Logger.
        # Additionally, the Rails logger makes no guarantees about this
        # behavior, so we'd be coupling to an implementation detail by depending
        # on it.
        severity = RubySeverity.new(event.severity)
        #temporary log message for ONYX-35595
        @logger.info(
          LogMessages::Util::LogBeforeFluentd.new(event.to_s)
        )
        @ruby_logger.log(severity, event.to_s, ::Audit::Event.progname)
      end
    end
  end
end
