# frozen_string_literal: true

class ConjurLogFormatter < Logger::Formatter
  Format = "%5s [%s] %s\n".freeze

  def initialize
    super
    @datetime_format = "%Y/%m/%d %H:%M:%S %z"
  end

  def call(severity, time, progname, msg)
    Format % [severity, format_datetime(time), msg2str(msg)]
  end
end
