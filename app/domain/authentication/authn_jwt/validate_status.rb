module Authentication
  module AuthnJwt

    ValidateStatus = CommandClass.new(
      dependencies: {
        fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
        discover_identity_provider: Authentication::OAuth::DiscoverIdentityProvider.new,
        create_signing_key: Authentication::AuthnJwt::CreateSigningKeyInterface.new,
        fetch_issuer_value: Authentication::AuthnJwt::FetchIssuerValue.new,
        validate_uri_parameters: Authentication::AuthnJwt::ValidateUriBasedParameters.new,
        fetch_identity_from_token: Authentication::AuthnJwt::IdentityFromDecodedTokenProvider
      },
      inputs: %i[authenticator_status_input]
    ) do

      def call
        create_authentication_parameters
        validate_service_id_exists
        validate_uri_based_parameters
        validate_secrets
      end

      private

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
        validate_issuer
        validate_identity_secrets
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
        authentication_input = Authentication::AuthenticatorInput.new(
          authenticator_name: @authenticator_status_input.authenticator_name,
          service_id: @authenticator_status_input.service_id,
          account: @authenticator_status_input.account,
          username: @authenticator_status_input.username,
          client_ip: @authenticator_status_input.client_ip,
          credentials: nil,
          request: nil
        )

        @authentication_parameters ||= Authentication::AuthnJwt::AuthenticationParameters.new(authentication_input)
      end
    end
  end
end

