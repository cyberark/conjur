require 'syslog'
require 'logger'
require 'time'

module Audit
  class << self
    {
      notice: [:info, Syslog::LOG_NOTICE],
      info: [:info, Syslog::LOG_INFO],
      warn: [:warn, Syslog::LOG_WARNING]
    }.each do |meth, details|
      logger_method, syslog_severity = details
      define_method meth do |msg, msgid, facility: nil, **data|
        logger.send logger_method, LogMessage.new(msg, msgid, data, syslog_severity, facility)
      end
    end

    def logger
      @logger ||= Rails.logger
    end

    attr_writer :logger
  end

  # RFC5424 structured data IDs
  module SDID
    # Conjur's Private Enterprise Number
    # cf. https://pen.iana.org
    CONJUR_PEN = 43868
    def self.conjur_sdid label
      [label, CONJUR_PEN].join('@').intern
    end

    POLICY = conjur_sdid 'policy'
    AUTH = conjur_sdid 'auth'
    SUBJECT = conjur_sdid 'subject'
    ACTION = conjur_sdid 'action'
  end

  class LogMessage < String
    def initialize msg, msgid, structured_data = nil, severity = nil, facility = nil
      super msg
      @msgid = msgid
      @structured_data = structured_data
      @severity = severity
      @facility = facility
    end

    attr_reader :msgid, :structured_data, :severity, :facility
  end

  # Middleware to store request ID in a thread variable
  class RememberUuid < Struct.new :app
    def call env
      Thread.current[:request_id] = env["action_dispatch.request_id"]
      app.call env
    end
  end

  class RFC5424Formatter
    SEVERITY_MAP = {
      Logger::Severity::DEBUG => Syslog::LOG_DEBUG,
      Logger::Severity::ERROR => Syslog::LOG_ERR,
      Logger::Severity::FATAL => Syslog::LOG_CRIT,
      Logger::Severity::INFO => Syslog::LOG_INFO,
      Logger::Severity::WARN => Syslog::LOG_WARNING
    }

    def call severity, time, progname, msg
      severity = if msg.respond_to? :severity
        msg.severity
      else
        SEVERITY_MAP[Logger::Severity.const_get severity] rescue severity
      end
      sd = msg.structured_data if msg.respond_to? :structured_data
      timestamp = time.utc.iso8601 3

      # Will be filled in by syslogd, however we might want to use a
      # different configured name on appliance instead.
      hostname = nil

      progname ||= 'conjur'

      # Use the request UUID when called with REST. Otherwise use PID.
      pid = Thread.current[:request_id] || Process.pid

      msgid = msg.msgid if msg.respond_to? :msgid
      sd = format_sd sd

      facility = msg.try(:facility) || 4

      fields = [timestamp, hostname, progname, pid, msgid, sd, msg]
      ["<#{severity + (facility << 3)}>1", *fields.map {|x| x || '-'}].join(" ") + "\n"
    end

  private
    def format_sd sd
      return '-' unless sd
      sd.map do |id, params|
        "[%s]" % [[id,
          params.map do |k, v|
            "#{k}=#{v.to_s.inspect}"
          end
        ].join(" ")]
      end.join
    end
  end
end

