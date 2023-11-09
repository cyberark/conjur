# frozen_string_literal: true

require 'logger'
require 'syslog'
require 'time'

class Logger
  class Formatter
    # RFC5424-compliant log formatter. If given a message that responds to 
    # severity, facility, message_id and/or structured_data, it'll use them.
    class RFC5424Formatter
      # NOTE: The _ parameter is severity, as defined by the Ruby logger.
      # However, we want the Syslog severity, which is what our audit events
      # produce by default.  Hence we get "severity" from "msg.severity".
      # "msg" is our Event object.
      #
      # :reek:LongParameterList here is to conform to Formatter interface.
      def self.call(_, time, progname, msg)
        Format.new(time: time, progname: progname, msg: msg).to_s
      end

      # Utility class that formats a single message
      class Format
        def initialize(time:, progname:, msg:)
          @msg = msg
          @time = time
          @progname = progname
          @msg = msg
        end

        def to_s
          audit_message = [
            header,
            timestamp,
            hostname,
            @progname,
            Format.pid,
            message_id,
            sd,
            @msg
          ].map {|part| part || '-'}.join(" ") + "\n"

          begin
            tenant_env = Rails.application.config.conjur_config.tenant_env
            if tenant_env == 'dev' || tenant_env == 'test'
              Rails.logger.info(
                LogMessages::Util::LogBeforeFluentd.new(audit_message)
              )
            end
          rescue => e
            Rails.logger.error(e.message)
          end
          audit_message
        end

        def header
          "<#{severity + facility}>1"
        end

        def severity
          @msg.severity
          # has_meth = @msg.respond_to?(:severity)
          # has_meth ? @msg.severity : Syslog::LOG_INFO
        end

        def facility
          @msg.facility
          # has_meth = @msg.respond_to?(:facility)
          # has_meth ? @msg.facility : Syslog::LOG_AUTH
        end

        def message_id
          @msg.message_id
          # has_meth = @msg.respond_to?(:message_id)
          # has_meth ? @msg.message_id : ""
        end

        def timestamp
          @time.utc.iso8601(3)
        end

        def hostname
          # Will be filled in by syslogd.
          nil
        end

        def sd
          # return unless @msg.respond_to?(:structured_data)
          return unless (sdata = @msg.structured_data)

          sdata.map do |id, params|
            format(
              "[%s]",
              [id, *Format.sd_parameters(params)].join(" ")
            )
          end.join
        end

        def self.pid
          # use http request id (as stored by Rack::RememberUuid) if available
          Thread.current[:request_id] || Process.pid
        end

        def self.sd_parameters params
          # Ensure quote, backslash, and closing square bracket are all escaped
          # per:
          # https://tools.ietf.org/html/rfc5424#section-6.3.3
          #
          # `inspect` handles quote and backslash, gsub handles the square
          # bracket
          params.map do |parameter, value|
            [parameter, value.to_s.inspect.gsub("]", "\\]")].join('=')
          end
        end
      end
    end
  end
end
