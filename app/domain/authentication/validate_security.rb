# frozen_string_literal: true

module Authentication
  ValidateSecurity = CommandClass.new(
    dependencies: {
      security: ::Authentication::Security.new
    },
    inputs: %i(input enabled_authenticators)
  ) do

    def call
      validate_security
    end

    private

    def validate_security
      @security.validate(@input.to_access_request(@enabled_authenticators))
    end
  end
end
