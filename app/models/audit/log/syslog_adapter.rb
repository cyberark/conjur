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
# The correct adapter, which depends on the environment, will configured
# automatically by the audit_socket.rb initializer.
module Audit
  module Log
    class SyslogAdapter
      def initialize(ruby_logger)
        @ruby_logger = ruby_logger
      end

      def log(event)
        @ruby_logger.log(event.severity, event, ::Audit::Event.progname)
      end
    end
  end
end
