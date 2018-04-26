require 'logger'

if path = Rails.application.config.try(:audit_socket)
  Audit.logger = Logger.new(UNIXSocket.open path).tap do |logger|
    logger.formatter = Audit::RFC5424Formatter.new
  end
end
