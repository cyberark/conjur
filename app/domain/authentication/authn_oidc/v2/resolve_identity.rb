module Authentication
  module AuthnOidc
    module V2
      class ResolveIdentity
        def call(identity:, account:, allowed_roles:)
          # make sure role has a resource (ex. user, host)
          roles = allowed_roles.select(&:resource?)

          roles.each do |role|
            role_account, _, role_id = role.id.split(':')
            return role if role_account == account && identity == role_id
          end

          raise(Errors::Authentication::Security::RoleNotFound, identity)

          # The following block has been removed from this initial release.  There
          # is concern that the experience of mapping users using annotations
          # will be confusing to administrators due to the requirement that the
          # identity value needs to be unique.

          # This code should be re-enabled cnce this PR has been merged:
          # https://github.com/cyberark/conjur/pull/2522

          annotated_roles = roles.select do |role|
            role.try(:resource).try(:annotation, 'authn-oidc/identity').to_s.downcase == identity.to_s.downcase &&
              role.id.split(':').first == account
          end
          raise(Errors::Authentication::Security::MultipleRoleMatchesFound, identity) if annotated_roles.length > 1
          raise(Errors::Authentication::Security::RoleNotFound, identity) if annotated_roles.empty?

          annotated_roles.first
        end
      end
    end
  end
end
