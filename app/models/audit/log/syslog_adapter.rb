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
        # NOTE: Below we translate the Syslog "event.severity" into a Ruby
        # Logger severity.  In our actual Syslog logging, this is simply thrown
        # away (see note on "call" method in "rfc5424_formatter.rb").  However,
        # _this_ adapter shouldn't have knowledge of that implementation detail,
        # so we provide the correct Ruby severity that the "log" interface
        # expects.
        severity = RubySeverity.new(event.severity)

        begin
          tenant_env = Rails.application.config.conjur_config.tenant_env
          if tenant_env == 'dev' || tenant_env == 'test'
            Rails.logger.info(
              LogMessages::Util::LogBeforeFluentd.new(event.to_s)
            )
          end
        rescue => e
          Rails.logger.error(e.message)
        end
        @ruby_logger.log(severity, event, ::Audit::Event.progname)
      end
    end
  end
end
