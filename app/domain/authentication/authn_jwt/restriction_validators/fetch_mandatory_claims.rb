require 'command_class'

module Authentication
  module AuthnJwt
    module RestrictionValidators
      # Fetch the mandatory claims from the JWT authenticator policy which enforce 
      # definition of annotations keys on JWT hosts 
      FetchMandatoryClaims = CommandClass.new(
        dependencies: {
          resource_class: ::Resource,
          fetch_required_secrets: ::Conjur::FetchRequiredSecrets.new,
          logger: Rails.logger
        },
        inputs: %i[authentication_parameters]
      ) do
        def call
          fetch_mandatory_claims
        end

        private

        def fetch_mandatory_claims
          # debug message start
          if !mandatory_claims_resource_exists?
            # debug message
            return empty_mandatory_claims
          else
            fetch_mandatory_claims_secret_value
            validate_mandatory_claims_secret_value
          end

          # info message end
          mandatory_claims_secret_value
        end
        
        def mandatory_claims_resource_exists?
          return @mandatory_claims_resource_exists unless @mandatory_claims_resource_exists.nil?

          @mandatory_claims_resource_exists ||= !mandatory_claims_resource.nil?
        end

        def mandatory_claims_resource
          @mandatory_claims_resource ||= @resource_class[mandatory_claims_resource_id]
        end

        def mandatory_claims_resource_id
          @mandatory_claims_resource_id ||= "#{@authentication_parameters.authn_jwt_variable_id_prefix}/#{MANDATORY_CLAIMS_RESOURCE_NAME}"
        end
        
        def empty_mandatory_claims
          @empty_mandatory_claims ||= []
        end
        
        def fetch_mandatory_claims_secret_value
          mandatory_claims_secret_value
        end

        def mandatory_claims_secret_value
          @mandatory_claims_secret_value ||= mandatory_claims_required_secret[mandatory_claims_resource_id]
        end
        
        def mandatory_claims_required_secret
          @mandatory_claims_required_secret ||= @fetch_required_secrets.call(resource_ids: [mandatory_claims_resource_id])
        end
        
        def validate_mandatory_claims_secret_value
          # debug message
          # validate secret structure
          # validate for forbidden values 
          # Raise new error
          # debug message
        end
      end
    end
  end
end
