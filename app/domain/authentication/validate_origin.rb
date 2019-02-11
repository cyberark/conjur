# frozen_string_literal: true

require 'types'
require 'util/error_class'
require 'authentication/webservice'
require 'authentication/webservices'

module Authentication
  ValidateOrigin = CommandClass.new(
    dependencies: {
      role_cls: ::Role
    },
    inputs: %i(input_to_validate)
  ) do

    def call
      validate_origin(@input_to_validate)
    end

    private

    def validate_origin(input)
      authn_role = role(input.username, input.account)
      raise InvalidOrigin unless authn_role.valid_origin?(input.origin)
    end

    def role(username, account)
      @role_cls.by_login(username, account: account)
    end
  end
end
