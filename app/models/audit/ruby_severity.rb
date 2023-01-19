# 0 Emergency    : system is unusable
# 1 Alert        : action must be taken immediately
# 2 Critical     : critical conditions
# 3 Error        : error conditions
# 4 Warning      : warning conditions
# 5 Notice       : normal but significant condition
# 6 Informational: informational messages
# 7 Debug        : debug-level messages
#
module Audit
  # RubySeverity, which represents a severity level defined in the standard
  # library's Logger class, is constructed from a Syslog severity level.  Thus
  # it encapsulates the knowledge of how to translate from Syslog to Ruby Logger
  # severity levels.

  # TODO: There is also the reverse one used in the rfc5424_formatter:
  #
  # SEVERITY_MAP = {
  #     Logger::Severity::DEBUG => Syslog::LOG_DEBUG,
  #     Logger::Severity::ERROR => Syslog::LOG_ERR,
  #     # TODO: is this right? (doesn't match reverse map)
  #     Logger::Severity::FATAL => Syslog::LOG_CRIT,
  #     Logger::Severity::INFO => Syslog::LOG_INFO,
  #     Logger::Severity::WARN => Syslog::LOG_WARNING
  # }.freeze
  class RubySeverity

    SYSLOG_TO_RUBY = {
      LOG_EMERG: :FATAL,
      LOG_ALERT: :FATAL,
      LOG_CRIT: :ERROR,
      LOG_ERR: :ERROR,
      LOG_WARNING: :WARN,
      LOG_NOTICE: :INFO,
      LOG_INFO: :INFO,
      LOG_DEBUG: :DEBUG
    }.map do |syslog, ruby|
      [Syslog::Level.const_get(syslog), Logger::Severity.const_get(ruby)]
    end.to_h.freeze

    def self.new(syslog_severity)
      SYSLOG_TO_RUBY[syslog_severity]
    end
  end
end
