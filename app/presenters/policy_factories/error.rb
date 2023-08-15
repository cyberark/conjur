module Presenter
  module PolicyFactories
    # Returns a Hash representation of an Failure Response to be used by the controller
    class Error
      # Response is always a FailureResponse
      def initialize(response:, response_codes: HTTP::Response::Status::SYMBOL_CODES)
        @response = response
        @response_codes = response_codes
      end

      def present
        {
          code: @response_codes[@response.status]
        }.tap do |rtn|
          rtn[:error] = format_error_message(@response.message)
        end
      end

      private

      def format_error_message(message)
        return message if message.is_a?(Array) || message.is_a?(Hash)

        { message: message.to_s }
      end
    end
  end
end
