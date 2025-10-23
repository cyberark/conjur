# frozen_string_literal: true

# These response objects provide a mechanism for passing more complex response
# information upstream

# Responsible for handling "failed" requests.
# Log level and Response code are both option.
module Responses
  class Failure
    attr_reader :message, :exception, :backtrace
    # allows the status to be changes in certain situations
    attr_accessor :status

    def initialize(message, level: :warn, status: :unauthorized, exception: nil, backtrace: nil)
      @message = message
      @level = level
      @status = status
      @exception = exception
      @backtrace = backtrace.nil? ? caller : backtrace # Add stack trace
    end

    def success?
      false
    end

    def level
      @level.to_sym
    end

    def to_s
      @message.to_s
    end

    # If the current response is a failure, further attempts to bind will just
    # return this response again.
    def bind
      self
    end

    # Escape hatch for imperative code that cannot work with railway programming.
    # Raises the underlying exception, allowing traditional exception-based error
    # handling to consume monadic responses. Use sparingly to avoid mixing paradigms.
    def bind!
      raise @exception
    end
  end
end
