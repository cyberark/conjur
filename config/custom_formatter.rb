# frozen_string_literal: true

class CustomFormatter < Logger::Formatter
  Format = "[%s] %5s | %s | %s | %s\n".freeze

  def initialize
    super
    @datetime_format = "%Y/%m/%d %H:%M:%S %z"
  end

  def call(severity, time, progname, msg)
    Format % [format_datetime(time), severity, pid, tid, msg2str(msg)]
  end

  private

  def pid
    $$
  end

  def tid
    Thread.current.object_id
  end
end
