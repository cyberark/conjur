module Authentication
  module AuthnOidc
    module V2
      class ResolveIdentity
        def call(identity:, account:, allowed_roles:)
          # make sure role has a resource (ex. user, host)
          roles = allowed_roles.select(&:resource?)

          # SECURITY - throw an exception if more than one match is found
          matching_roles = roles.filter do |role|
            role_account, _, role_id = role.id.split(':')
            role_account == account && role_id == identity
          end

          return matching_roles.first if matching_roles.count == 1

          raise(Errors::Authentication::Security::RoleNotFound, identity) if matching_roles.count.zero?

          # SECURITY - need to make it clear in logs that there are multiple matching roles
          raise(Errors::Authentication::Security::TooManyRoles, identity)
        end
      end
    end
  end
end
