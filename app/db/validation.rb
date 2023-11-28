# frozen_string_literal: true

module DB
  # This class provides a generic mechanism for running Dry-RB contracts
  # against provided data.
  class Validation
    def initialize(contract, logger: Rails.logger)
      @contract = contract&.new
      @logger = logger

      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    def validate(data)
      return @success.new(data) if @contract.blank?

      result = @contract.call(**data)
      if result.success?
        @success.new(result.to_h)
      else
        # If contract fails, return the first defined exception...
        error = result.errors.first
        # If this is an authenticator validation and a field is missing, we want to return an alternative error.
        if error.text == 'is missing' &&
            @contract.class.to_s.match(/\AAuthentication::Authn\w+::V2::Validations::AuthenticatorConfiguration\z/)
          type = @contract.class.to_s.split('::')[1].underscore.dasherize

          return @failure.new(
            "Value '#{error.path.first}' #{error.text}",
            status: :unauthorized,
            exception: Errors::Conjur::RequiredSecretMissing.new(
              "#{data[:account]}:variable:conjur/#{type}/#{data[:service_id]}/#{error.path.first.to_s.dasherize}"
            )
          )
        end
        @failure.new(error, exception: error.meta[:exception])
      end
    end
  end

end
