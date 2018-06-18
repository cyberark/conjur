require 'logger'
require 'syslog'
require 'time'

require 'active_support'
require 'active_support/core_ext/object/try'

require 'util/struct'

class Logger
  class Formatter
    # RFC5424-compliant log formatter. If given a message that responds to 
    # severity, facility, message_id and/or structured_data, it'll use them.
    class RFC5424Formatter
      # The :reek:LongParameterList here is to conform to Formatter interface.
      def self.call severity, time, progname, msg
        Format.new(severity: severity, time: time, progname: progname, msg: msg).to_s
      end

      # Utility class that formats a single message
      class Format < Util::Struct
        field :severity, :time, :progname, :msg

        SEVERITY_MAP = {
          Logger::Severity::DEBUG => Syslog::LOG_DEBUG,
          Logger::Severity::ERROR => Syslog::LOG_ERR,
          Logger::Severity::FATAL => Syslog::LOG_CRIT,
          Logger::Severity::INFO => Syslog::LOG_INFO,
          Logger::Severity::WARN => Syslog::LOG_WARNING
        }.freeze

        def to_s
          [header, timestamp, hostname, progname, Format.pid, msgid, sd, msg]
            .map {|part| part || '-'}.join(" ") + "\n"
        end

        def header
          "<#{severity + facility}>1"
        end

        def severity
          msg.try(:severity) || SEVERITY_MAP[super]
        end

        def facility
          msg.try(:facility) || Syslog::LOG_AUTH
        end

        def timestamp
          time.utc.iso8601 3
        end

        def hostname
          # Will be filled in by syslogd.
          nil
        end

        def msgid
          msg.try :message_id
        end

        def sd
          return unless (sdata = msg.try(:structured_data))
          sdata.map do |id, params|
            format "[%s]", [id, *Format.sd_parameters(params)].join(" ")
          end.join
        end

        def self.pid
          # use http request id (as stored by Rack::RememberUuid) if available
          Thread.current[:request_id] || Process.pid
        end

        def self.sd_parameters params
          params.map { |parameter, value| [parameter, value.to_s.inspect].join('=') }
        end
      end
    end
  end
end
