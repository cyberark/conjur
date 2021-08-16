require 'command_class'

module Authentication
  module AuthnJwt
    module RestrictionValidation
      # Fetch the mapping claims from the JWT authenticator policy which enforce
      # definition of annotations keys on JWT hosts 
      FetchMappingClaims = CommandClass.new(
        dependencies: {
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new,
          fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
          parse_mapping_claims: ::Authentication::AuthnJwt::InputValidation::ParseMappingClaims.new,
          logger: Rails.logger
        },
        inputs: %i[authentication_parameters]
      ) do
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
            conjur_account: @authentication_parameters.account,
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
            var_name: MAPPING_CLAIMS_RESOURCE_NAME
          )
        end

        def fetch_mapping_claims_secret_value
          mapping_claims_secret_value
        end

        def mapping_claims_secret_value
          @mapping_claims_secret_value ||= @fetch_authenticator_secrets.call(
            conjur_account: @authentication_parameters.account,
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
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
