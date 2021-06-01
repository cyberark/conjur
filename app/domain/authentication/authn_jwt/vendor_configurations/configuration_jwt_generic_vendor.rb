module Authentication
  module AuthnJwt
    module VendorConfigurations
      # Mock JWTConfiguration class to use it to develop other part in the jwt authenticator
      class ConfigurationJWTGenericVendor < ConfigurationInterface

        def initialize(authenticator_input)
          @authentication_parameters_class = Authentication::AuthnJwt::AuthenticationParameters
          @extract_token_from_credentials = Authentication::AuthnJwt::InputValidation::ExtractTokenFromCredentials.new
          @validate_and_decode_token_class = Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken
          @identity_provider_factory = Authentication::AuthnJwt::IdentityProviders::CreateIdentityProvider
          @validate_resource_restrictions_class = Authentication::ResourceRestrictions::ValidateResourceRestrictions
          @create_identity_provider_class = Authentication::AuthnJwt::IdentityProviders::CreateIdentityProvider
          @logger = Rails.logger
          init_authentication_parameters(authenticator_input)
        end

        def jwt_identity
          @jwt_identity ||= jwt_identity_from_request
        end

        def validate_restrictions
          initialize_validate_restrictions
          @validate_resource_restrictions.call(
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
            account: @authentication_parameters.account,
            role_name: jwt_identity,
            constraints: @constraints,
            authentication_request: @restriction_validator.new(
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

        def init_authentication_parameters(authenticator_input)
          @logger.debug(LogMessages::Authentication::AuthnJwt::CREATING_AUTHENTICATION_PARAMETERS_OBJECT.new)
          jwt_token = @extract_token_from_credentials.call(
            credentials: authenticator_input.request.body.read
          )
          @authentication_parameters = @authentication_parameters_class.new(
            authentication_input: authenticator_input,
            jwt_token: jwt_token
          )
        end

        def jwt_identity_from_request
          @jwt_identity_from_request ||= identity_provider.jwt_identity
        end

        def identity_provider
          @identity_provider ||= @create_identity_provider_class.new.call(
            authentication_parameters: @authentication_parameters
          )
        end

        def validate_and_decode_token_instance
          @validate_and_decode_token_instance ||= @validate_and_decode_token_class.new(
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
              ::Authentication::AuthnJwt::SigningKey::FetchCachedSigningKey.new(
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

        def fetch_singing_key_interface
          @fetch_singing_key_interface ||= create_signing_key_interface.call(
            authentication_parameters: @authentication_parameters
          )
        end

        def create_signing_key_interface
          @create_signing_key_interface ||= Authentication::AuthnJwt::SigningKey::CreateSigningKeyInterface.new
        end

        def fetch_jwt_claims_to_validate
          @fetch_jwt_claims_to_validate ||= ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new
        end

        def initialize_validate_restrictions
          @restriction_validator = Authentication::AuthnJwt::RestrictionValidators::ValidateRestrictionsOneToOne
          @restrictions_from_annotations_class = Authentication::ResourceRestrictions::GetServiceSpecificRestrictionFromAnnotation
          @extract_resource_restrictions = Authentication::ResourceRestrictions::ExtractResourceRestrictions.new(
            get_restriction_from_annotation: @restrictions_from_annotations_class,
            ignore_empty_annotations: false
          )
          @validate_resource_restrictions = @validate_resource_restrictions_class.new(extract_resource_restrictions: @extract_resource_restrictions)
          @constraints = Authentication::Constraints::MultipleConstraint.new(
            Authentication::Constraints::NotEmptyConstraint.new
          )
        end
      end
    end
  end
end
