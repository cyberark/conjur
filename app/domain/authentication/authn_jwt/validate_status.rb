module Authentication
  module AuthnJwt

    ValidateStatus = CommandClass.new(
      dependencies: {
        create_signing_key: Authentication::AuthnJwt::CreateSigningKeyInterface.new,
        fetch_issuer_value: Authentication::AuthnJwt::FetchIssuerValue.new,
        fetch_identity_from_token: Authentication::AuthnJwt::IdentityFromDecodedTokenProvider,
        validate_webservice_is_whitelisted: ::Authentication::Security::ValidateWebserviceIsWhitelisted.new,
        validate_role_can_access_webservice: ::Authentication::Security::ValidateRoleCanAccessWebservice.new,
        validate_webservice_exists: ::Authentication::Security::ValidateWebserviceExists.new,
        enabled_authenticators: Authentication::InstalledAuthenticators.enabled_authenticators_str(ENV),
        validate_account_exists: ::Authentication::Security::ValidateAccountExists.new,
        logger: Rails.logger
      },
      inputs: %i[authenticator_status_input]
    ) do
      extend(Forwardable)
      def_delegators(:@authenticator_status_input, :authenticator_name, :account,
                     :username, :status_webservice, :service_id, :client_ip)

      def call
        validate_generic_status_validations
        validate_secrets
      end

      private

      def validate_generic_status_validations
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatingJwtStatusConfiguration.new)
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
      end

      def validate_service_id_exists
        raise Errors::Authentication::AuthnJwt::ServiceIdMissing.new unless service_id
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedStatusServiceIdExists.new)
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

      def validate_secrets
        validate_signing_key_secrets
        validate_issuer
        validate_identity_secrets
      end

      def validate_signing_key_secrets
        @create_signing_key.call(authentication_parameters: authentication_parameters)
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedSigningKeyConfiguration.new)
      end

      def validate_issuer
        @fetch_issuer_value.call(authentication_parameters: authentication_parameters)
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedIssuerConfiguration.new)
      end

      def validate_identity_secrets
        @fetch_identity_from_token.new(authentication_parameters).identity_configured_properly?
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedIdentityConfiguration.new)
      end

      def authentication_parameters
        @authentication_parameters ||= Authentication::AuthnJwt::AuthenticationParameters.new(
          authentication_input: Authentication::AuthenticatorInput.new(
            authenticator_name: authenticator_name,
            service_id: service_id,
            account: account,
            username: username,
            client_ip: client_ip,
            credentials: nil,
            request: nil
          ),
          jwt_token: nil
        )
      end

      def webservice
        @webservice ||= ::Authentication::Webservice.new(
          account: account,
          authenticator_name: authenticator_name,
          service_id: service_id
        )
      end
    end
  end
end
