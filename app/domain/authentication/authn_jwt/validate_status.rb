module Authentication
  module AuthnJwt

    ValidateStatus = CommandClass.new(
      dependencies: {
        create_signing_key_provider: Authentication::AuthnJwt::SigningKey::CreateSigningKeyProvider.new,
        fetch_issuer_value: Authentication::AuthnJwt::ValidateAndDecode::FetchIssuerValue.new,
        fetch_audience_value: Authentication::AuthnJwt::ValidateAndDecode::FetchAudienceValue.new,
        fetch_enforced_claims: Authentication::AuthnJwt::RestrictionValidation::FetchEnforcedClaims.new,
        fetch_claim_aliases: Authentication::AuthnJwt::RestrictionValidation::FetchClaimAliases.new,
        validate_identity_configured_properly: Authentication::AuthnJwt::IdentityProviders::ValidateIdentityConfiguredProperly.new,
        validate_webservice_is_whitelisted: ::Authentication::Security::ValidateWebserviceIsWhitelisted.new,
        validate_role_can_access_webservice: ::Authentication::Security::ValidateRoleCanAccessWebservice.new,
        validate_webservice_exists: ::Authentication::Security::ValidateWebserviceExists.new,
        validate_account_exists: ::Authentication::Security::ValidateAccountExists.new,
        authenticator_input_class: Authentication::AuthenticatorInput,
        jwt_authenticator_input_class: Authentication::AuthnJwt::JWTAuthenticatorInput,
        logger: Rails.logger
      },
      inputs: %i[authenticator_status_input enabled_authenticators]
    ) do
      extend(Forwardable)
      def_delegators(:@authenticator_status_input, :authenticator_name, :account,
                     :username, :status_webservice, :service_id, :client_ip)

      def call
        @logger.info(LogMessages::Authentication::AuthnJwt::ValidatingJwtStatusConfiguration.new)
        validate_generic_status_validations
        validate_signing_key
        validate_issuer
        validate_audience
        validate_enforced_claims
        validate_claim_aliases
        validate_identity_secrets
        @logger.info(LogMessages::Authentication::AuthnJwt::ValidatedJwtStatusConfiguration.new)
      end

      private

      def validate_generic_status_validations
        validate_account_exists
        validate_service_id_exists
        validate_user_has_access_to_status_webservice
        validate_authenticator_webservice_exists
        validate_webservice_is_whitelisted
      end

      def validate_account_exists
        @validate_account_exists.(
          account: account
        )
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedAccountExists.new)
      end

      def validate_service_id_exists
        raise Errors::Authentication::AuthnJwt::ServiceIdMissing unless service_id

        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedServiceIdExists.new)
      end

      def validate_user_has_access_to_status_webservice
        @validate_role_can_access_webservice.(
          webservice: status_webservice,
          account: account,
          user_id: username,
          privilege: 'read'
        )
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedUserHasAccessToStatusWebservice.new)
      end

      def validate_authenticator_webservice_exists
        @validate_webservice_exists.(
          webservice: webservice,
          account: account
        )
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedAuthenticatorWebServiceExists.new)
      end

      def validate_webservice_is_whitelisted
        @validate_webservice_is_whitelisted.(
          webservice: webservice,
          account: account,
          enabled_authenticators: @enabled_authenticators
        )
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedStatusWebserviceIsWhitelisted.new)
      end

      def validate_issuer
        @fetch_issuer_value.call(authenticator_input: authenticator_input)
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedIssuerConfiguration.new)
      end

      def validate_audience
        @fetch_audience_value.call(authenticator_input: authenticator_input)
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedAudienceConfiguration.new)
      end

      def validate_enforced_claims
        @fetch_enforced_claims.call(jwt_authenticator_input: jwt_authenticator_input)
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedEnforcedClaimsConfiguration.new)
      end

      def validate_claim_aliases
        @fetch_claim_aliases.call(jwt_authenticator_input: jwt_authenticator_input)
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedClaimAliasesConfiguration.new)
      end

      def validate_identity_secrets
        @validate_identity_configured_properly.call(
          jwt_authenticator_input: jwt_authenticator_input
        )
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedIdentityConfiguration.new)
      end

      def jwt_authenticator_input
        @jwt_authenticator_input ||= @jwt_authenticator_input_class.new(
          authenticator_input: authenticator_input,
          decoded_token: nil
        )
      end

      def authenticator_input
        @authenticator_input ||= @authenticator_input_class.new(
          authenticator_name: authenticator_name,
          service_id: service_id,
          account: account,
          username: username,
          client_ip: client_ip,
          credentials: nil,
          request: nil
        )
      end

      def webservice
        @webservice ||= ::Authentication::Webservice.new(
          account: account,
          authenticator_name: authenticator_name,
          service_id: service_id
        )
      end

      def validate_signing_key
        signing_key_provider.call(
          force_fetch: false
        )
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedSigningKeyConfiguration.new)
      end

      def signing_key_provider
        @signing_key_provider ||= @create_signing_key_provider.call(
          authenticator_input: authenticator_input
        )
      end
    end
  end
end
