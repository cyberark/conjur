module Authentication
  module AuthnJwt
    module SigningKey
      # Factory that returns the interface implementation of FetchSigningKey
      CreateSigningKeyProvider ||= CommandClass.new(
        dependencies: {
          fetch_provider_uri_signing_key_class: Authentication::AuthnJwt::SigningKey::FetchProviderUriSigningKey,
          fetch_jwks_uri_signing_key_class: Authentication::AuthnJwt::SigningKey::FetchJwksUriSigningKey,
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new,
          logger: Rails.logger
        },
        inputs: %i[authentication_parameters]
      ) do
        def call
          @logger.debug(LogMessages::Authentication::AuthnJwt::SelectingSigningKeyInterface.new)
          create_signing_key_provider
        end

        private

        def create_signing_key_provider
          if provider_uri_resource_exists? and !jwks_uri_has_resource_exists?
            fetch_provider_uri_signing_key
          elsif jwks_uri_has_resource_exists? and !provider_uri_resource_exists?
            fetch_jwks_uri_signing_key
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
            conjur_account: @authentication_parameters.account,
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
            var_name: PROVIDER_URI_RESOURCE_NAME
          )
        end

        def fetch_provider_uri_signing_key
          @logger.info(
            LogMessages::Authentication::AuthnJwt::SelectedSigningKeyInterface.new(PROVIDER_URI_INTERFACE_NAME)
          )
          @fetch_provider_uri_signing_key ||= @fetch_provider_uri_signing_key_class.new(
            authentication_parameters: @authentication_parameters
          )
        end

        def jwks_uri_has_resource_exists?
          # defined? is needed for memoization of boolean value
          return @jwks_uri_has_resource_exists if defined?(@jwks_uri_has_resource_exists)

          @jwks_uri_has_resource_exists = @check_authenticator_secret_exists.call(
            conjur_account: @authentication_parameters.account,
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
            var_name: JWKS_URI_RESOURCE_NAME
          )
        end

        def fetch_jwks_uri_signing_key
          @logger.info(
            LogMessages::Authentication::AuthnJwt::SelectedSigningKeyInterface.new(JWKS_URI_INTERFACE_NAME)
          )
          @fetch_jwks_uri_signing_key ||= @fetch_jwks_uri_signing_key_class.new(
            authentication_parameters: @authentication_parameters
          )
        end
      end
    end
  end
end
