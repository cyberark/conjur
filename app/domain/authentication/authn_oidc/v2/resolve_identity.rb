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
            role_account, _, role_id = role[:role_id].split(':')
            next unless role_account == @authenticator.account

            return role[:role_id] if identifier == role_id
          end

          raise(Errors::Authentication::Security::RoleNotFound, identifier)
        end
      end
    end
  end
end
