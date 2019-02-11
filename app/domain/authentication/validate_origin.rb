# frozen_string_literal: true

require 'types'

module Authentication
  ValidateOrigin = CommandClass.new(
    dependencies: {
      get_role_by_login: GetRoleByLogin.new
    },
    inputs: %i(input)
  ) do

    def call
      validate_origin
    end

    private

    def validate_origin
      authn_role = role(@input.username, @input.account)
      raise InvalidOrigin unless authn_role.valid_origin?(@input.origin)
    end

    def role(username, account)
      @get_role_by_login.(username: username, account: account)
    end
  end
end
