module Authentication
  module AuthnJwt
    module VendorConfigurations
      # Mock JWTConfiguration class to use it to develop other part in the jwt authenticator
      class ConfigurationJWTGenericVendor
        # These are dependencies in class integrating different parts of the jwt authentication
        # :reek:CountKeywordArgs
        def initialize(
          authenticator_input:,
          logger: Rails.logger,
          authentication_parameters_class: Authentication::AuthnJwt::AuthenticationParameters,
          restriction_validator_class: Authentication::AuthnJwt::RestrictionValidation::ValidateRestrictionsOneToOne,
          validate_resource_restrictions_class: Authentication::ResourceRestrictions::ValidateResourceRestrictions,
          extract_token_from_credentials: Authentication::AuthnJwt::InputValidation::ExtractTokenFromCredentials.new,
          create_identity_provider: Authentication::AuthnJwt::IdentityProviders::CreateIdentityProvider.new,
          create_constraints: Authentication::AuthnJwt::RestrictionValidation::CreateConstrains.new,
          fetch_mapping_claims: Authentication::AuthnJwt::RestrictionValidation::FetchMappingClaims.new,
          validate_and_decode_token: Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new
        )
          @logger = logger
          @authentication_parameters_class = authentication_parameters_class
          @restriction_validator_class = restriction_validator_class
          @validate_resource_restrictions_class = validate_resource_restrictions_class
          @extract_token_from_credentials = extract_token_from_credentials
          @create_identity_provider = create_identity_provider
          @create_constraints = create_constraints
          @fetch_mapping_claims = fetch_mapping_claims
          @validate_and_decode_token = validate_and_decode_token

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
              decoded_token: @authentication_parameters.decoded_token,
              mapped_claims: mapped_claims
            )
          )
        rescue Errors::Authentication::Constraints::NonPermittedRestrictionGiven => e
          raise Errors::Authentication::AuthnJwt::RoleWithRegisteredOrMappedClaimError, e.inspect
        end

        def validate_and_decode_token
          @authentication_parameters.decoded_token = @validate_and_decode_token.call(
            authentication_parameters: @authentication_parameters
          )
        end

        private

        def jwt_token(authenticator_input)
          @extract_token_from_credentials.call(
            credentials: authenticator_input.request.body.read
          )
        end

        def mapped_claims
          @mapped_claims ||= @fetch_mapping_claims.call(authentication_parameters: @authentication_parameters)
        end

        def jwt_identity_from_request
          @jwt_identity_from_request ||= identity_provider.jwt_identity
        end

        def identity_provider
          @identity_provider ||= create_identity_provider.call(
            authentication_parameters: @authentication_parameters
          )
        end

        def fetch_singing_key_interface
          @fetch_singing_key_interface ||= create_signing_key_interface.call(
            authentication_parameters: @authentication_parameters
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
          @constraints ||= @create_constraints.call(
            authentication_parameters: @authentication_parameters,
            base_non_permitted_annotations: CLAIMS_DENY_LIST
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
