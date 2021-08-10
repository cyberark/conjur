require 'command_class'

module Authentication
  module AuthnJwt
    module RestrictionValidation
      # Fetch the enforced claims from the JWT authenticator policy which enforce 
      # definition of annotations keys on JWT hosts 
      FetchEnforcedClaims = CommandClass.new(
        dependencies: {
          resource_class: ::Resource,
          fetch_required_secrets: ::Conjur::FetchRequiredSecrets.new,
          parse_enforced_claims: ::Authentication::AuthnJwt::InputValidation::ParseEnforcedClaims.new,
          logger: Rails.logger
        },
        inputs: %i[authentication_parameters]
      ) do

        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingEnforcedClaims.new)
          
          return empty_enforced_claims unless enforced_claims_resource_exists?

          fetch_enforced_claims_secret_value
          parse_enforced_claims_secret_value
        end

        private
        
        def enforced_claims_resource_exists?
          return @enforced_claims_resource_exists unless @enforced_claims_resource_exists.nil?

          @enforced_claims_resource_exists ||= !enforced_claims_resource.nil?
        end

        def enforced_claims_resource
          @enforced_claims_resource ||= @resource_class[enforced_claims_resource_id]
        end

        def enforced_claims_resource_id
          @enforced_claims_resource_id ||= "#{@authentication_parameters.authn_jwt_variable_id_prefix}/#{ENFORCED_CLAIMS_RESOURCE_NAME}"
        end
        
        def empty_enforced_claims
          @logger.debug(LogMessages::Authentication::AuthnJwt::NotConfiguredEnforcedClaims.new)
          @empty_enforced_claims ||= []
        end
        
        def fetch_enforced_claims_secret_value
          enforced_claims_secret_value
        end

        def enforced_claims_secret_value
          @enforced_claims_secret_value ||= enforced_claims_required_secret[enforced_claims_resource_id]
        end
        
        def enforced_claims_required_secret
          @enforced_claims_required_secret ||= @fetch_required_secrets.call(resource_ids: [enforced_claims_resource_id])
        end
        
        def parse_enforced_claims_secret_value
          return @parse_enforced_claims_secret_value if @parse_enforced_claims_secret_value

          @parse_enforced_claims_secret_value ||= @parse_enforced_claims.call(enforced_claims: enforced_claims_secret_value)
          @logger.info(LogMessages::Authentication::AuthnJwt::FetchedEnforcedClaims.new(@parse_enforced_claims_secret_value))
          
          @parse_enforced_claims_secret_value
        end
      end
    end
  end
end
