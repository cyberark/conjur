# frozen_string_literal: true

require 'authentication/errors'

module Authentication
  class ValidateOrigin
    extend CommandClass::Include

    InvalidOrigin = Authentication::InvalidOrigin

    command_class(
      dependencies: {
        role_cls: ::Role
      },
      inputs: %i(input)
    ) do

      def call
        raise InvalidOrigin unless role.valid_origin?(@input.origin)
      end

      private

      def role
        @role_cls.by_login(@input.username, account: @input.account)
      end
    end
  end
end
