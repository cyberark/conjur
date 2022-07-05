module Authentication
  module AuthnOidc
    module V2
      class ResolveIdentity
        def call(identity:, account:, allowed_roles:)
          # binding.pry
          # make sure role has a resource (ex. user, host)
          roles = allowed_roles.select { |role| role.resource? }

          roles.each do |role|
            role_account, _, role_id = role.id.split(':')
            return role if role_account == account && identity == role_id
          end

          annotated_roles = []
          roles.each do |role|
            role_account = role.id.split(':').first
            next unless role_account == account

            # Don't love the performance...
            if role.resource.annotation('authn-oidc/identity').to_s.downcase == identity.to_s.downcase
              annotated_roles.push(role)
            end
          end
          raise "Multiple annotations match identity: #{identity}" if annotated_roles.length > 1
          raise Errors::Authentication::Security::RoleNotFound, identity unless  annotated_roles.first

          annotated_roles.first
        end
      end
    end
  end
end
