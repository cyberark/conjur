require 'logger'
require 'logger/formatter/rfc5424_formatter'

if path = Rails.application.config.try(:audit_socket)
  Audit.logger = Logger.new(UNIXSocket.open path).tap do |logger|
    logger.formatter = Logger::Formatter::RFC5424Formatter
  end
end
