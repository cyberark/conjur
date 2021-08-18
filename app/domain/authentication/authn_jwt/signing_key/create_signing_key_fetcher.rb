module Authentication
  module AuthnJwt
    module SigningKey
      # Factory that returns the interface implementation of FetchSigningKey
      CreateSigningKeyFetcher ||= CommandClass.new(
        dependencies: {
          fetch_provider_uri_signing_key: Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey.new,
          fetch_jwks_uri_signing_key: Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey.new,
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new,
          logger: Rails.logger
        },
        inputs: %i[authenticator_input]
      ) do
        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::SelectingSigningKeyInterface.new)
          create_signing_key_provider
        end

        private

        def create_signing_key_provider
          if provider_uri_resource_exists? and !jwks_uri_has_resource_exists?
            provider_uri_signing_key_provide_fetcher
          elsif jwks_uri_has_resource_exists? and !provider_uri_resource_exists?
            jwks_uri_signing_key_fetcher
          else
            raise Errors::Authentication::AuthnJwt::InvalidUriConfiguration.new(
              PROVIDER_URI_RESOURCE_NAME,
              JWKS_URI_RESOURCE_NAME
            )
          end
        end

        def provider_uri_resource_exists?
          # defined? is needed for memoization of boolean value
          return @provider_uri_resource_exists if defined?(@provider_uri_resource_exists)

          @provider_uri_resource_exists = @check_authenticator_secret_exists.call(
            conjur_account: @authenticator_input.account,
            authenticator_name: @authenticator_input.authenticator_name,
            service_id: @authenticator_input.service_id,
            var_name: PROVIDER_URI_RESOURCE_NAME
          )
        end

        def provider_uri_signing_key_provide_fetcher
          @logger.info(
            LogMessages::Authentication::AuthnJwt::SelectedSigningKeyInterface.new(PROVIDER_URI_INTERFACE_NAME)
          )
          @fetch_provider_uri_signing_key
        end

        def jwks_uri_has_resource_exists?
          # defined? is needed for memoization of boolean value
          return @jwks_uri_has_resource_exists if defined?(@jwks_uri_has_resource_exists)

          @jwks_uri_has_resource_exists = @check_authenticator_secret_exists.call(
            conjur_account: @authenticator_input.account,
            authenticator_name: @authenticator_input.authenticator_name,
            service_id: @authenticator_input.service_id,
            var_name: JWKS_URI_RESOURCE_NAME
          )
        end

        def jwks_uri_signing_key_fetcher
          @logger.info(
            LogMessages::Authentication::AuthnJwt::SelectedSigningKeyInterface.new(JWKS_URI_INTERFACE_NAME)
          )
          @fetch_jwks_uri_signing_key
        end
      end
    end
  end
end
