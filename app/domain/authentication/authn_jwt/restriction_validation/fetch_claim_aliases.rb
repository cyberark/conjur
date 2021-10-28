require 'command_class'

module Authentication
  module AuthnJwt
    module RestrictionValidation
      # Fetch the claim aliases from the JWT authenticator policy which enforce
      # definition of annotations keys on JWT hosts 
      FetchClaimAliases = CommandClass.new(
        dependencies: {
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new,
          fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
          parse_claim_aliases: ::Authentication::AuthnJwt::InputValidation::ParseClaimAliases.new,
          logger: Rails.logger
        },
        inputs: %i[jwt_authenticator_input]
      ) do
        extend(Forwardable)
        def_delegators(:@jwt_authenticator_input, :service_id, :authenticator_name, :account)

        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingClaimAliases.new)
          
          return empty_claim_aliases unless claim_aliases_resource_exists?

          fetch_claim_aliases_secret_value
          parse_claim_aliases_secret_value
        end

        private

        def empty_claim_aliases
          @logger.debug(LogMessages::Authentication::AuthnJwt::NotConfiguredClaimAliases.new)
          @empty_claim_aliases ||= {}
        end

        def claim_aliases_resource_exists?
          return @claim_aliases_resource_exists if defined?(@claim_aliases_resource_exists)

          @claim_aliases_resource_exists ||= @check_authenticator_secret_exists.call(
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
            var_name: CLAIM_ALIASES_RESOURCE_NAME
          )
        end

        def fetch_claim_aliases_secret_value
          claim_aliases_secret_value
        end

        def claim_aliases_secret_value
          @claim_aliases_secret_value ||= @fetch_authenticator_secrets.call(
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
            required_variable_names: [CLAIM_ALIASES_RESOURCE_NAME]
          )[CLAIM_ALIASES_RESOURCE_NAME]
        end
        
        def parse_claim_aliases_secret_value
          claim_aliases
        end

        def claim_aliases
          return @claim_aliases if @claim_aliases

          @claim_aliases ||= @parse_claim_aliases.call(claim_aliases: claim_aliases_secret_value)
          @logger.info(LogMessages::Authentication::AuthnJwt::FetchedClaimAliases.new(@claim_aliases))

          @claim_aliases
        end
      end
    end
  end
end
