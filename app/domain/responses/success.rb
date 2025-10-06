# frozen_string_literal: true

# These response objects provide a mechanism for passing more complex response
# information upstream

# Responsible for handling "successful" requests. The
# response is returned via the `.result` method.
module Responses
  class Success
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
end
