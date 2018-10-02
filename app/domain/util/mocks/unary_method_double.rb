module Util
  module Mocks
    # Creates a double with a single method whose return values (and, optionally,
    # errors) are specified by the given hashes.
    #
    class UnaryMethodDouble
      # @param method_name [Symbol] Name of method we're faking
      # @param return_vals [Hash]   Happy path. Keys are inputs, values are what
      #                             to return.
      # @param errors      [Hash]   Sad path. Keys are inputs that should raise
      #                             an error, values are the error class to raise.
      # @return                     An instance with the single method specified.
      #
      def initialize(method_name:, return_vals:, errors: {})
        @return_vals = return_vals
        @errors = errors
        define_singleton_method(method_name, method(:handle_input))
      end

      private

      def handle_input(arg)
        return @return_vals[arg] if @return_vals.key?(arg)
        raise @errors[arg] if @errors.key?(arg)
        raise "The double wasn't configured for the input #{arg}"
      end
    end
  end
end
