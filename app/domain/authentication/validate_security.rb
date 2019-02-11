# frozen_string_literal: true

require 'types'
require 'util/error_class'
require 'authentication/webservice'
require 'authentication/webservices'

module Authentication
  ValidateSecurity = CommandClass.new(
    dependencies: {
      security: ::Authentication::Security.new
    },
    inputs: %i(input_to_validate env)
  ) do

    def call
      validate_security(@input_to_validate)
    end

    private

    def validate_security(input)
      @security.validate(input.to_access_request(@env))
    end
  end
end
