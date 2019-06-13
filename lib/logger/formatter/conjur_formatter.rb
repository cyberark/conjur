# frozen_string_literal: true

class ConjurFormatter < Logger::Formatter
  Format = "%5s [%s] [tid=%s] [pid=%s] %s\n".freeze

  def initialize
    super
    @datetime_format = "%Y/%m/%d %H:%M:%S %z"
  end

  def call(severity, time, progname, msg)
    Format % [severity, format_datetime(time), tid, pid, msg2str(msg)]
  end

  private

  def tid
    Thread.current.object_id
  end

  def pid
    $$
  end
end
