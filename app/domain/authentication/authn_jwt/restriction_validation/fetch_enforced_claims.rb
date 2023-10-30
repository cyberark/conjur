require 'command_class'

module Authentication
  module AuthnJwt
    module RestrictionValidation
      # Fetch the enforced claims from the JWT authenticator policy which enforce 
      # definition of annotations keys on JWT hosts 
      FetchEnforcedClaims = CommandClass.new(
        dependencies: {
          fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new,
          parse_enforced_claims: ::Authentication::AuthnJwt::InputValidation::ParseEnforcedClaims.new,
          logger: Rails.logger
        },
        inputs: %i[jwt_authenticator_input]
      ) do
        extend(Forwardable)
        def_delegators(:@jwt_authenticator_input, :service_id, :authenticator_name, :account)

        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingEnforcedClaims.new)
          
          return empty_enforced_claims unless enforced_claims_resource_exists?

          fetch_enforced_claims_secret_value
          parse_enforced_claims_secret_value
        end

        private
        
        def enforced_claims_resource_exists?
          return @enforced_claims_resource_exists if defined?(@enforced_claims_resource_exists)

          @enforced_claims_resource_exists ||= @check_authenticator_secret_exists.call(
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
            var_name: ENFORCED_CLAIMS_RESOURCE_NAME
          )
        end
        
        def empty_enforced_claims
          @logger.debug(LogMessages::Authentication::AuthnJwt::NotConfiguredEnforcedClaims.new)
          @empty_enforced_claims ||= []
        end
        
        def fetch_enforced_claims_secret_value
          enforced_claims_secret_value
        end

        def enforced_claims_secret_value
          @enforced_claims_secret_value ||= @fetch_authenticator_secrets.call(
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
            required_variable_names: [ENFORCED_CLAIMS_RESOURCE_NAME]
          )[ENFORCED_CLAIMS_RESOURCE_NAME]
        end
        
        def parse_enforced_claims_secret_value
          return @parse_enforced_claims_secret_value if @parse_enforced_claims_secret_value

          @parse_enforced_claims_secret_value ||= @parse_enforced_claims.call(enforced_claims: enforced_claims_secret_value)
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchedEnforcedClaims.new(@parse_enforced_claims_secret_value))
          
          @parse_enforced_claims_secret_value
        end
      end
    end
  end
end
