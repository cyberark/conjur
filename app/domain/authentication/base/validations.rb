# frozen_string_literal: true

module Authentication
  module Base
    class Validations < Dry::Validation::Contract

      # key is the context we're adding this custom error to
      def failed_response(error:, key:)
        key.failure(exception: error, text: error.message)
      end

    end
  end
end
