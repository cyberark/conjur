module Authentication
  module AuthnJwt

    ValidateStatus = CommandClass.new(
      dependencies: {
        create_signing_key: Authentication::AuthnJwt::CreateSigningKeyInterface.new,
        fetch_issuer_value: Authentication::AuthnJwt::FetchIssuerValue.new,
        validate_uri_parameters: Authentication::AuthnJwt::ValidateUriBasedParameters.new,
        fetch_identity_from_token: Authentication::AuthnJwt::IdentityFromDecodedTokenProvider,
        validate_webservice_is_whitelisted: ::Authentication::Security::ValidateWebserviceIsWhitelisted.new,
        validate_role_can_access_webservice: ::Authentication::Security::ValidateRoleCanAccessWebservice.new,
        validate_webservice_exists: ::Authentication::Security::ValidateWebserviceExists.new,
        enabled_authenticators: Authentication::InstalledAuthenticators.enabled_authenticators_str(ENV),
        logger: Rails.logger
      },
      inputs: %i[authenticator_status_input]
    ) do
      extend(Forwardable)
      def_delegators(:@authenticator_status_input, :authenticator_name, :account,
                     :username, :webservice, :status_webservice)

      def call
        validate_generic_status_validations
        create_authentication_parameters
        validate_uri_based_parameters
        validate_secrets
      end

      private

      def validate_generic_status_validations
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatingJwtStatusConfiguration.new)
        validate_user_has_access_to_status_webservice
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedUserHasAccessToStatusWebservice.new)
        validate_authenticator_webservice_exists
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedAuthenticatorWebServiceExists.new)
        validate_webservice_is_whitelisted
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedStatusWebserviceIsWhitelisted.new)
        validate_service_id_exists
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedStatusServiceIdExists.new)
      end

      def validate_user_has_access_to_status_webservice
        @validate_role_can_access_webservice.(
          webservice: status_webservice,
            account: account,
            user_id: username,
            privilege: 'read'
        )
      end

      def validate_webservice_is_whitelisted
        @validate_webservice_is_whitelisted.(
          webservice: webservice,
            account: account,
            enabled_authenticators: @enabled_authenticators
        )
      end

      def validate_authenticator_webservice_exists
        @validate_webservice_exists.(
          webservice: webservice,
            account: account
        )
      end

      def validate_service_id_exists
        raise Errors::Authentication::AuthnJwt::ServiceIdMissing unless @authenticator_status_input.service_id
      end

      def validate_uri_based_parameters
        @validate_uri_parameters.call(authenticator_input: @authenticator_status_input,
                                          enabled_authenticators: Authentication::InstalledAuthenticators.enabled_authenticators_str(ENV)
        )
      end

      def validate_secrets
        validate_signing_key_secrets
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedSigningKeyConfiguration.new)
        validate_issuer
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedIssuerConfiguration.new)
        validate_identity_secrets
        @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedIdentityConfiguration.new)
      end

      def validate_signing_key_secrets
        @create_signing_key.call(authentication_parameters: @authentication_parameters)
      end

      def validate_issuer
        @fetch_issuer_value.call(authentication_parameters: @authentication_parameters)
      end

      def validate_identity_secrets
        @fetch_identity_from_token.new(@authentication_parameters).identity_configured_properly?
      end

      def required_variable_names
        @required_variable_names ||= %w[provider-uri]
      end

      def create_authentication_parameters
        @authentication_parameters ||= Authentication::AuthnJwt::AuthenticationParameters.new(Authentication::AuthenticatorInput.new(
                                                                                              authenticator_name: @authenticator_status_input.authenticator_name,
                                                                                              service_id: @authenticator_status_input.service_id,
                                                                                              account: @authenticator_status_input.account,
                                                                                              username: @authenticator_status_input.username,
                                                                                              client_ip: @authenticator_status_input.client_ip,
                                                                                              credentials: nil,
                                                                                              request: nil
                                                                                            )
        )
      end
    end
  end
end

