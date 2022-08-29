module Authentication
  module AuthnOidc
    module V2
      class IdentityResolver
        def call(identity:, account:, allowed_roles:)
          # make sure role has a resource (ex. user, host)
          roles = allowed_roles.select(&:resource?)

          roles.each do |role|
            role_account, _, role_id = role.id.split(':')
            return role if role_account == account && identity == role_id
          end

          raise(Errors::Authentication::Security::RoleNotFound, identity)
        end
      end
    end
  end
end
