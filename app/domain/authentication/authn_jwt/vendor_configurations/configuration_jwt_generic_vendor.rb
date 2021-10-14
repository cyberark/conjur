module Authentication
  module AuthnJwt
    module VendorConfigurations
      # Mock JWTConfiguration class to use it to develop other part in the jwt authenticator
      #
      # validate_resource_restrictions is a dependency and there is no reason for variable assumption warning about it.
      # :reek:InstanceVariableAssumption
      class ConfigurationJWTGenericVendor
        # These are dependencies in class integrating different parts of the jwt authentication
        # rubocop:disable Metrics/ParameterLists
        # :reek:CountKeywordArgs
        def initialize(
          authenticator_input:,
          logger: Rails.logger,
          jwt_authenticator_input_class: Authentication::AuthnJwt::JWTAuthenticatorInput,
          restriction_validator_class: Authentication::AuthnJwt::RestrictionValidation::ValidateRestrictionsOneToOne,
          validate_resource_restrictions_class: Authentication::ResourceRestrictions::ValidateResourceRestrictions,
          extract_resource_restrictions_class: Authentication::ResourceRestrictions::ExtractResourceRestrictions,
          extract_token_from_credentials: Authentication::AuthnJwt::InputValidation::ExtractTokenFromCredentials.new,
          create_identity_provider: Authentication::AuthnJwt::IdentityProviders::CreateIdentityProvider.new,
          create_constraints: Authentication::AuthnJwt::RestrictionValidation::CreateConstrains.new,
          fetch_claim_aliases: Authentication::AuthnJwt::RestrictionValidation::FetchClaimAliases.new,
          validate_and_decode_token: Authentication::AuthnJwt::ValidateAndDecode::ValidateAndDecodeToken.new,
          restrictions_from_annotations: Authentication::ResourceRestrictions::GetServiceSpecificRestrictionFromAnnotation.new
        )
          @logger = logger
          @jwt_authenticator_input_class = jwt_authenticator_input_class
          @restriction_validator_class = restriction_validator_class
          @validate_resource_restrictions_class = validate_resource_restrictions_class
          @extract_resource_restrictions_class = extract_resource_restrictions_class
          @extract_token_from_credentials = extract_token_from_credentials
          @create_identity_provider = create_identity_provider
          @create_constraints = create_constraints
          @fetch_claim_aliases = fetch_claim_aliases
          @validate_and_decode_token = validate_and_decode_token
          @restrictions_from_annotations = restrictions_from_annotations
          @authenticator_input = authenticator_input
          @jwt_token = jwt_token
        end
        # rubocop:enable Metrics/ParameterLists

        def jwt_identity
          @jwt_identity ||= jwt_identity_from_request
        end

        def validate_restrictions
          validate_resource_restrictions.call(
            authenticator_name: @jwt_authenticator_input.authenticator_name,
            service_id: @jwt_authenticator_input.service_id,
            account: @jwt_authenticator_input.account,
            role_name: jwt_identity,
            constraints: constraints,
            authentication_request: @restriction_validator_class.new(
              decoded_token: @jwt_authenticator_input.decoded_token,
              aliased_claims: aliased_claims
            )
          )
        rescue Errors::Authentication::Constraints::NonPermittedRestrictionGiven => e
          raise Errors::Authentication::AuthnJwt::RoleWithRegisteredOrClaimAliasError, e.inspect
        end

        def validate_and_decode_token
          decoded_token = @validate_and_decode_token.call(
            authenticator_input: @authenticator_input,
            jwt_token: jwt_token
          )
          @logger.debug(LogMessages::Authentication::AuthnJwt::CreatingJWTAuthenticationInputObject.new)
          @jwt_authenticator_input = @jwt_authenticator_input_class.new(
            authenticator_input: @authenticator_input,
            decoded_token: decoded_token
          )
        end

        private

        def jwt_token
          @jwt_token ||= @extract_token_from_credentials.call(
            credentials: @authenticator_input.request.body.read
          )
        end

        def aliased_claims
          @aliased_claims ||= @fetch_claim_aliases.call(
            jwt_authenticator_input: @jwt_authenticator_input
          )
        end

        def jwt_identity_from_request
          @jwt_identity_from_request ||= identity_provider.call(
            jwt_authenticator_input: @jwt_authenticator_input
          )
        end

        def identity_provider
          @identity_provider ||= @create_identity_provider.call(
            jwt_authenticator_input: @jwt_authenticator_input
          )
        end

        def extract_resource_restrictions
          @extract_resource_restrictions ||= @extract_resource_restrictions_class.new(
            get_restriction_from_annotation: @restrictions_from_annotations,
            ignore_empty_annotations: false
          )
        end

        def constraints
          @constraints ||= @create_constraints.call(
            jwt_authenticator_input: @jwt_authenticator_input,
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
