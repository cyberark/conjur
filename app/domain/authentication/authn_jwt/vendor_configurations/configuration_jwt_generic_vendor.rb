module Authentication
  module AuthnJwt
    module VendorConfigurations
      # Mock JWTConfiguration class to use it to develop other part in the jwt authenticator
      class ConfigurationJWTGenericVendor < ConfigurationInterface

        def initialize(authenticator_input)
          super

          @logger = Rails.logger

          @logger.debug(LogMessages::Authentication::AuthnJwt::CREATING_AUTHENTICATION_PARAMETERS_OBJECT.new)
          @authentication_parameters = authentication_parameters_class.new(
            authentication_input: authenticator_input,
            jwt_token: jwt_token(authenticator_input)
          )
        end

        def jwt_identity
          @jwt_identity ||= jwt_identity_from_request
        end

        def validate_restrictions
          validate_resource_restrictions.call(
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
            account: @authentication_parameters.account,
            role_name: jwt_identity,
            constraints: constraints,
            authentication_request: restriction_validator_class.new(
              decoded_token: @authentication_parameters.decoded_token
            )
          )
        end

        def validate_and_decode_token
          @authentication_parameters.decoded_token = validate_and_decode_token_instance.call(
            authentication_parameters: @authentication_parameters
          )
        end

        private

        def jwt_token(authenticator_input)
          extract_token_from_credentials.call(
            credentials: authenticator_input.request.body.read
          )
        end

        def jwt_identity_from_request
          @jwt_identity_from_request = identity_provider.jwt_identity
        end

        def identity_provider
          @identity_provider = create_identity_provider.call(
            authentication_parameters: @authentication_parameters
          )
        end

        def validate_and_decode_token_instance
          @validate_and_decode_token_instance ||= validate_and_decode_token_class.new(
            fetch_signing_key: fetch_signing_key,
            fetch_jwt_claims_to_validate: fetch_jwt_claims_to_validate
          )
        end

        def fetch_signing_key
          @fetch_signing_key ||= fetch_cached_signing_key
        end

        def fetch_cached_signing_key
          @fetch_cached_signing_key ||= ::Util::ConcurrencyLimitedCache.new(
            ::Util::RateLimitedCache.new(
              fetch_cached_signing_key_class.new(
                fetch_singing_key_interface: fetch_singing_key_interface
              ),
              refreshes_per_interval: CACHE_REFRESHES_PER_INTERVAL,
              rate_limit_interval: CACHE_RATE_LIMIT_INTERVAL,
              logger: Rails.logger
            ),
            max_concurrent_requests: CACHE_MAX_CONCURRENT_REQUESTS,
            logger: Rails.logger
          )
        end

        def authentication_parameters_class
          @authentication_parameters_class ||= Authentication::AuthnJwt::AuthenticationParameters
        end

        def extract_token_from_credentials
          @extract_token_from_credentials ||= Authentication::AuthnJwt::InputValidation::ExtractTokenFromCredentials.new
        end

        def validate_and_decode_token_class
          @validate_and_decode_token_class ||= Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken
        end

        def validate_resource_restrictions_class
          @validate_resource_restrictions_class ||= Authentication::ResourceRestrictions::ValidateResourceRestrictions
        end

        def create_identity_provider
          @create_identity_provider ||= Authentication::AuthnJwt::IdentityProviders::CreateIdentityProvider.new
        end

        def fetch_singing_key_interface
          @fetch_singing_key_interface ||= create_signing_key_interface.call(
            authentication_parameters: @authentication_parameters
          )
        end

        def fetch_cached_signing_key_class
          @fetch_cached_signing_key_class ||= Authentication::AuthnJwt::SigningKey::FetchCachedSigningKey
        end

        def create_signing_key_interface
          @create_signing_key_interface ||= Authentication::AuthnJwt::SigningKey::CreateSigningKeyInterface.new
        end

        def fetch_jwt_claims_to_validate
          @fetch_jwt_claims_to_validate ||= ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new
        end

        def restriction_validator_class
          @restriction_validator_class ||= Authentication::AuthnJwt::RestrictionValidators::ValidateRestrictionsOneToOne
        end

        def restrictions_from_annotations
          @restrictions_from_annotations ||= Authentication::ResourceRestrictions::GetServiceSpecificRestrictionFromAnnotation.new
        end

        def extract_resource_restrictions
          @extract_resource_restrictions ||= Authentication::ResourceRestrictions::ExtractResourceRestrictions.new(
            get_restriction_from_annotation: restrictions_from_annotations,
            ignore_empty_annotations: false
          )
        end

        def constraints
          @constraints ||= Authentication::Constraints::MultipleConstraint.new(
            Authentication::Constraints::NotEmptyConstraint.new
          )
        end

        def validate_resource_restrictions
          @validate_resource_restrictions ||= validate_resource_restrictions_class.new(extract_resource_restrictions: extract_resource_restrictions)
        end
      end
    end
  end
end
