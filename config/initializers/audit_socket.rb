# frozen_string_literal: true

require 'logger'
require 'logger/formatter/rfc5424_formatter'

# A lot is happening in this small snippet:
#
# 1. The Audit logger is being changed to our custom RFC5424 compliant logger IF
#    a certain unix socket exists.  This RFC5424 compliant logger is constructed
#    in a curious way, worth explaining...
#
# 2. First, an instance of ruby's standard lib logger is created with the unix
#    socket as its "log device" (ie: its output "file").
#
# 3. That default logger is then configured by setting its formatter.  The
#    formatter API is interesting: It requires a Proc whose call method takes
#    4 arguments:
#
#        call(severity, time, progname, msg)
#
#    According to the docs, that call method "should return an Object that can
#    be written to the logging device via write".  This means, afaict, either
#    a String or something with a `to_s` method.  Our custom formatter returns
#    an object with a `to_s` method.
#
#    Formatter docs:
#    https://ruby-doc.org/stdlib-2.5.1/libdoc/logger/rdoc/Logger.html#class-Logger-label-Format

Audit.logger = if path = Rails.application.config.try(:audit_socket)
  # TODO: Add tests for this.  Our CI isn't verifying if we've broken anything.
  Audit::Log::SyslogAdapter.new(
    Logger.new(UNIXSocket.open(path)).tap do |logger|
      logger.formatter = Logger::Formatter::RFC5424Formatter
    end
  )
# We don't want this to affect Conjur OSS production deploys
elsif Rails.env.development?
  # NOTE: Use Syslog format for audit events so we can write e2e tests against
  # what actually appears in the log.  We don't want this to affect our other
  # logging because the ConjurFormatter produces more human-friendly logs.
  #
  # NOTE: We need to use the relative path "./log/development.log"
  # because in the CI environment (see "ci/docker-compose.yml") the
  # cucumber and conjur containers mount the log volume at different
  # absolute paths ("/src" vs "/opt").  Otoh, in LogHelpers::LOG_LOCATION
  # -- which this code is coupled to -- we can use the absolute
  # path "/src" since that runs in the cucumber container.
  Audit::Log::SyslogAdapter.new(
    Logger.new("./log/development.log").tap do |logger|
      logger.formatter = Logger::Formatter::RFC5424Formatter
    end
  )
end
