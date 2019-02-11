# frozen_string_literal: true

GetRoleByLogin = CommandClass.new(
  dependencies: {
    role_cls: ::Role
  },
  inputs: %i(username account)
) do

  def call
    role
  end

  private

  def role
    @role_cls.by_login(@username, account: @account)
  end
end
