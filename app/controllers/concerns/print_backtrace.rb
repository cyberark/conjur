# frozen_string_literal: true

module PrintBacktrace
  extend ActiveSupport::Concern

  def log_backtrace(err)
    backtrace = err.backtrace
    if logger.level != :debug
      backtrace = backtrace.select do |line|
        # We want to print a minimal stack trace in INFO level so that it is easier
        # to understand the issue. To do this, we filter the trace output to only
        # Conjur application code, and not code from the Gem dependencies.
        # We still want to print the full stack trace (including the Gem dependencies
        # code) so we print it in DEBUG level.
        !line.include?(ENV['GEM_HOME'])
      end
    end
    logger.error(backtrace.join("\n"))
  end
end
