module Util
  GetUsernameFromRoleId = CommandClass.new(
    dependencies: {
      role_class: ::Role
    },
    inputs: %i(role_id)
  ) do

    def call
      username_from_role_id
    end

    private

    def username_from_role_id
      @role_class.username_from_roleid(@role_id)
    end
  end
end
