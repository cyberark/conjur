# frozen_string_literal: true

module DB
  # This class provides a generic mechanism for running Dry-RB contracts
  # against provided data.
  class Validation
    def initialize(validations:, logger: Rails.logger)
      @validations = validations
      @logger = logger

      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    def validate(data:)
      return @success.new(data) if @validations.blank?

      result = @validations.call(**data)
      if result.success?
        @success.new(result.to_h)
      else
        errors = result.errors
        # Print all errors
        @logger.info(errors.to_h.inspect)

        # If contract fails, return the first defined exception...
        error = errors.first
        @failure.new(error, exception: error.meta[:exception])
      end
    end
  end
end
