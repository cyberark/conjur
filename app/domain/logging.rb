# frozen_string_literal: true

# Enhance log messages with the place where they were called from.
# Puts class name and method name in the log message at the beginning, e.g.:
#   "BranchController#show: branch_id = 123, name = 'test'"
#   "Domain::AnnotationService#create_annotation: resource_id = 123, name = 'test'"
# Search for @logger or logger and use it if present.
# For calling log_error method, the Rails.logger is used if none of these is present.

require 'active_support/concern'
module Logging
  def log_info(msg)
    l = use_logger
    return unless l&.info?

    l.info(log_msg(msg))
  end

  def log_debug(msg)
    l = use_logger
    return unless l&.debug?

    l.debug(log_msg(msg))
  end

  def log_error(msg)
    l = use_logger || Rails.logger
    l&.error(log_msg(msg))
  end

  private

  def use_logger
    @logger || logger
  end

  def log_msg(msg)
    "#{log_meta}: #{msg}"
  end
  
  def log_meta
    "#{self.class}##{caller[2][/`([^']*)'/, 1]}"
  end
end
