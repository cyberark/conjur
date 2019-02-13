# frozen_string_literal: true

module Authentication
  ValidateOrigin = CommandClass.new(
    dependencies: {
      get_role_by_login: GetRoleByLogin.new
    },
    inputs: %i(input)
  ) do

    def call
      authn_role = role(@input.username, @input.account)
      raise InvalidOrigin unless authn_role.valid_origin?(@input.origin)
    end

    private

    def role(username, account)
      @get_role_by_login.(username: username, account: account)
    end
  end
end
