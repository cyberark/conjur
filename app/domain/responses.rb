# frozen_string_literal: true

# These response objects provide a mechanism for passing more complex response
# information upstream

# Responsible for handling "successful" requests. The
# response is returned via the `.result` method.
class SuccessResponse
  attr_reader :result, :status

  def initialize(result, status: :ok)
    @result = result
    @status = status
  end

  def success?
    true
  end

  # The result of bind should always be another Response object, if the current
  # response object is successful, #bind will call the next operation
  def bind(&_block)
    yield(result)
  end

  # Escape hatch for imperative code that cannot work with railway programming.
  # Returns the underlying result directly, allowing traditional return-value-based
  # handling to consume monadic responses. Use sparingly to avoid mixing paradigms.
  def bind!
    @result
  end
end

# Responsible for handling "failed" requests.
# Log level and Response code are both option.
class FailureResponse
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
