# frozen_string_literal: true

module Audit
  module Event
    class Authn
      # RoleId, in the context of authentication, is subtly different from an
      # ordinary "role_id".  This is because an authn event can fail when the
      # user or host authenticating doesn't exist.  In this case, the "role_id"
      # becomes "what the role id would be if the user _did_ exist". In all
      # other cases, it's the actual "role_id" for the existing user.
      #
      # The control parameter smell here is intentional: This is the object
      # that is hiding the "nil"-ugliness.
      # :reek:ControlParameter
      class RoleId
        ACCOUNT_PLACEHOLDER = "ACCOUNT_MISSING"
        USERNAME_PLACEHOLDER = "USERNAME_MISSING"

        # NOTE: "username" may refer to a user or host.
        def initialize(role:, account:, username:)
          @role = role
          @account = account || ACCOUNT_PLACEHOLDER
          @username = username || USERNAME_PLACEHOLDER
        end

        def to_s
          @role&.id || Role.roleid_from_username(@account, @username)
        end
      end
    end
  end
end
