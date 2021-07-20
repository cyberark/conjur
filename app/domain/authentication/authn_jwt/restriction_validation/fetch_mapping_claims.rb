require 'command_class'

module Authentication
  module AuthnJwt
    module RestrictionValidation
      # Fetch the mapping claims from the JWT authenticator policy which enforce
      # definition of annotations keys on JWT hosts 
      FetchMappingClaims = CommandClass.new(
        dependencies: {
          resource_class: ::Resource,
          fetch_required_secrets: ::Conjur::FetchRequiredSecrets.new,
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
          @empty_mapping_claims ||= Hash.new
        end

        def mapping_claims_resource_exists?
          return @mapping_claims_resource_exists unless @mapping_claims_resource_exists.nil?

          @mapping_claims_resource_exists ||= !mapping_claims_resource.nil?
        end

        def mapping_claims_resource
          @mapping_claims_resource ||= @resource_class[mapping_claims_resource_id]
        end

        def mapping_claims_resource_id
          @mapping_claims_resource_id ||= "#{@authentication_parameters.authn_jwt_variable_id_prefix}/#{MAPPING_CLAIMS_RESOURCE_NAME}"
        end

        def fetch_mapping_claims_secret_value
          mapping_claims_secret_value
        end

        def mapping_claims_secret_value
          @mapping_claims_secret_value ||= mapping_claims_required_secret[mapping_claims_resource_id]
        end
        
        def mapping_claims_required_secret
          @mapping_claims_required_secret ||= @fetch_required_secrets.call(resource_ids: [mapping_claims_resource_id])
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
