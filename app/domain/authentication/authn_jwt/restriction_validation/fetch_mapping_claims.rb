require 'command_class'

module Authentication
  module AuthnJwt
    module RestrictionValidation
      # Fetch the claim aliases from the JWT authenticator policy which enforce
      # definition of annotations keys on JWT hosts 
      FetchMappingClaims = CommandClass.new(
        dependencies: {
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new,
          fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
          parse_mapping_claims: ::Authentication::AuthnJwt::InputValidation::ParseMappingClaims.new,
          logger: Rails.logger
        },
        inputs: %i[jwt_authenticator_input]
      ) do
        extend(Forwardable)
        def_delegators(:@jwt_authenticator_input, :service_id, :authenticator_name, :account)

        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingMappingClaims.new)
          
          return empty_mapping_claims unless mapping_claims_resource_exists?

          fetch_mapping_claims_secret_value
          parse_mapping_claims_secret_value
        end

        private

        def empty_mapping_claims
          @logger.debug(LogMessages::Authentication::AuthnJwt::NotConfiguredMappingClaims.new)
          @empty_mapping_claims ||= {}
        end

        def mapping_claims_resource_exists?
          return @mapping_claims_resource_exists if defined?(@mapping_claims_resource_exists)

          @mapping_claims_resource_exists ||= @check_authenticator_secret_exists.call(
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
            var_name: MAPPING_CLAIMS_RESOURCE_NAME
          )
        end

        def fetch_mapping_claims_secret_value
          mapping_claims_secret_value
        end

        def mapping_claims_secret_value
          @mapping_claims_secret_value ||= @fetch_authenticator_secrets.call(
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
            required_variable_names: [MAPPING_CLAIMS_RESOURCE_NAME]
          )[MAPPING_CLAIMS_RESOURCE_NAME]
        end
        
        def parse_mapping_claims_secret_value
          mapping_claims
        end

        def mapping_claims
          return @mapping_claims if @mapping_claims

          @mapping_claims ||= @parse_mapping_claims.call(mapping_claims: mapping_claims_secret_value)
          @logger.info(LogMessages::Authentication::AuthnJwt::FetchedMappingClaims.new(@mapping_claims))

          @mapping_claims
        end
      end
    end
  end
end
