# frozen_string_literal: true

module Authentication

  ValidateAuthenticatorExist = CommandClass.new(
    dependencies: {
    },
    inputs: %i(input authenticator)
  ) do

    def call
      validate_authenticator_exists
    end

    private

    def validate_authenticator_exists
      raise AuthenticatorNotFound, @input.authenticator_name unless @authenticator
    end
  end
end
