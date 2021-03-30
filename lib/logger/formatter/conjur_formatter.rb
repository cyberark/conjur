# frozen_string_literal: true

class ConjurFormatter < Logger::Formatter
  Format = "%5s %s [pid=%s] %s\n"

  def initialize
    super
    @datetime_format = "%Y/%m/%d %H:%M:%S %z"
  end

  def call(severity, time, _progname, msg)
    format(Format, severity, format_datetime(time), pid, msg2str(msg))
  end

  private

  def pid
    $$
  end
end
