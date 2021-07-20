module Authentication
  module AuthnJwt
    module VendorConfigurations
      # Mock JWTConfiguration class to use it to develop other part in the jwt authenticator
      class ConfigurationJWTGenericVendor < ConfigurationInterface

        def initialize(
          authenticator_input:,
          logger: Rails.logger,
          authentication_parameters_class: Authentication::AuthnJwt::AuthenticationParameters,
          restriction_validator_class: Authentication::AuthnJwt::RestrictionValidation::ValidateRestrictionsOneToOne,
          validate_and_decode_token_class:  Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken,
          validate_resource_restrictions_class: Authentication::ResourceRestrictions::ValidateResourceRestrictions,
          extract_token_from_credentials: Authentication::AuthnJwt::InputValidation::ExtractTokenFromCredentials.new,
          create_identity_provider: Authentication::AuthnJwt::IdentityProviders::CreateIdentityProvider.new

        )
          @logger = logger
          @authentication_parameters_class = authentication_parameters_class
          @restriction_validator_class = restriction_validator_class
          @validate_and_decode_token_class = validate_and_decode_token_class
          @validate_resource_restrictions_class = validate_resource_restrictions_class
          @extract_token_from_credentials = extract_token_from_credentials
          @create_identity_provider = create_identity_provider

          @logger.debug(LogMessages::Authentication::AuthnJwt::CreatingAuthenticationParametersObject.new)
          @authentication_parameters = @authentication_parameters_class.new(
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
            authentication_request: @restriction_validator_class.new(
              decoded_token: @authentication_parameters.decoded_token
            )
          )
        end

        def validate_and_decode_token
          @authentication_parameters.decoded_token = validate_and_decode_token_instance.call(
            authentication_parameters: @authentication_parameters,
            fetch_signing_key: fetch_signing_key
          )
        end

        private

        def jwt_token(authenticator_input)
          @extract_token_from_credentials.call(
            credentials: authenticator_input.request.body.read
          )
        end

        def jwt_identity_from_request
          @jwt_identity_from_request ||= identity_provider.jwt_identity
        end

        def identity_provider
          @identity_provider ||= create_identity_provider.call(
            authentication_parameters: @authentication_parameters
          )
        end

        def validate_and_decode_token_instance
          return @validate_and_decode_token_instance if @validate_and_decode_token_instance

          @logger.debug(LogMessages::Authentication::AuthnJwt::CreateValidateAndDecodeTokenInstance.new)
          @validate_and_decode_token_instance = @validate_and_decode_token_class.new(
            fetch_jwt_claims_to_validate: fetch_jwt_claims_to_validate
          )
          @logger.debug(LogMessages::Authentication::AuthnJwt::CreatedValidateAndDecodeTokenInstance.new)
          @validate_and_decode_token_instance
        end

        def fetch_signing_key
          @fetch_signing_key ||= ::Util::ConcurrencyLimitedCache.new(
            ::Util::RateLimitedCache.new(
              fetch_signing_key_interface,
              refreshes_per_interval: CACHE_REFRESHES_PER_INTERVAL,
              rate_limit_interval: CACHE_RATE_LIMIT_INTERVAL,
              logger: @logger
            ),
            max_concurrent_requests: CACHE_MAX_CONCURRENT_REQUESTS,
            logger: @logger
          )
        end

        def create_identity_provider
          @logger.debug(LogMessages::Authentication::AuthnJwt::CreateJwtIdentityProviderInstance.new)
          @create_identity_provider ||= @create_identity_provider
          @logger.debug(LogMessages::Authentication::AuthnJwt::CreatedJwtIdentityProviderInstance.new)
          @create_identity_provider
        end

        def fetch_signing_key_interface
          @fetch_signing_key_interface ||= create_signing_key_interface.call(
            authentication_parameters: @authentication_parameters
          )
        end

        def create_signing_key_interface
          @create_signing_key_interface ||= Authentication::AuthnJwt::SigningKey::CreateSigningKeyFactory.new
        end

        def fetch_jwt_claims_to_validate
          @fetch_jwt_claims_to_validate ||= ::Authentication::AuthnJwt::ValidateAndDecode::FetchJwtClaimsToValidate.new
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
          @logger.debug(LogMessages::Authentication::AuthnJwt::CreateJwtRestrictionsValidatorInstance.new)
          @validate_resource_restrictions ||= @validate_resource_restrictions_class.new(extract_resource_restrictions: extract_resource_restrictions)
          @logger.debug(LogMessages::Authentication::AuthnJwt::CreatedJwtRestrictionsValidatorInstance.new)
          @validate_resource_restrictions
        end
      end
    end
  end
end
