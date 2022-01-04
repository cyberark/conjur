module Authentication
  module AuthnJwt
    module SigningKey
      # This class is responsible for fetching JWK Set from JWKS-uri
      FetchSigningKeySettingsFromVariables ||= CommandClass.new(
        dependencies: {
          etch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new
        },
        inputs: %i[authenticator_input]
      ) do
        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::SelectingSigningKeyInterface.new)
          create_signing_key_provider
        end

        private

        def fetch_provider_uri_signing_key
          @logger.info(
            LogMessages::Authentication::AuthnJwt::SelectedSigningKeyInterface.new(PROVIDER_URI_INTERFACE_NAME)
          )
          @fetch_provider_uri_signing_key ||= @fetch_provider_uri_signing_key_class.new(
            authenticator_input: @authenticator_input,
            fetch_signing_key: @fetch_signing_key
          )
        end

        def fetch_jwks_uri_signing_key
          @logger.info(
            LogMessages::Authentication::AuthnJwt::SelectedSigningKeyInterface.new(JWKS_URI_INTERFACE_NAME)
          )
          @fetch_jwks_uri_signing_key ||= @fetch_jwks_uri_signing_key_class.new(
            authenticator_input: @authenticator_input,
            fetch_signing_key: @fetch_signing_key
          )
        end
    end
  end
end