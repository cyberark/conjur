# frozen_string_literal: true

# These response objects provide a mechanism for passing more complex response
# information upstream

# Responsible for handling "successful" requests. The
# response is returned via the `.result` method.
class SuccessResponse
  attr_reader :result

  def initialize(result)
    @result = result
  end

  def success?
    true
  end

  # The result of bind should always be another Response object, if the current
  # response object is successful, #bind will call the next operation
  def bind(&_block)
    yield(result)
  end
end

# Responsible for handling "failed" requests.
# Log level and Response code are both option.
class FailureResponse
  attr_reader :status

  def initialize(message, level: :warn, status: :unauthorized)
    @message = message
    @level = level
    @status = status
  end

  def success?
    false
  end

  def level
    @level.to_sym
  end

  def message
    case @message
    when Array
      @message
    when Hash
      @message
    else
      { message: @message.to_s }
    end
  end

  def to_h
    {
      code: HTTP::Response::Status::SYMBOL_CODES[@status]
    }.tap do |rtn|
      rtn[:error] = message
    end
  end

  # If the current response is a failure, further attempts to bind will just
  # return this response again.
  def bind
    self
  end
end
