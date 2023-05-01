module Authentication
  module AuthnOidc
    module V2
      class ResolveIdentity
        def initialize(authenticator:, logger: Rails.logger)
          @authenticator = authenticator
          @logger = logger
        end

        def call(identifier:, allowed_roles:, id: nil)
          allowed_roles.each do |role|
            next unless match?(identifier: identifier, role: role)

            return role[:role_id]
          end

          raise(Errors::Authentication::Security::RoleNotFound, identifier)
        end

        def match?(identifier:, role:)
          role_account, _, role_id = role[:role_id].split(':')
          role_account == @authenticator.account && identifier == role_id
        end
      end
    end
  end
end
