module Authentication
  module AuthnOidc
    module V2
      class ResolveIdentity
        def call(identity:, account:, allowed_roles:)
          # make sure role has a resource (ex. user, host)
          roles = allowed_roles.select(&:resource?)  # { |role| role.resource? }

          roles.each do |role|
            role_account, _, role_id = role.id.split(':')
            return role if role_account == account && identity == role_id
          end

          annotated_roles = roles.select do |role|
            role.resource.annotation('authn-oidc/identity').to_s.downcase == identity.to_s.downcase &&
              role.id.split(':').first == account
          end
          raise Errors::Authentication::Security::MultipleRoleMatchesFound, identity if annotated_roles.length > 1
          raise Errors::Authentication::Security::RoleNotFound, identity unless  annotated_roles.first

          annotated_roles.first
        end
      end
    end
  end
end
