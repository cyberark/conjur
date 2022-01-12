module Authentication
  module AuthnJwt
    module SigningKey
      # This class is responsible for variables permutation validation
      FetchSigningKeySettingsFromVariables ||= CommandClass.new(
        dependencies: {
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new,
          fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new
        },
        inputs: %i[authenticator_input]
      ) do
        def call
          fetch_signing_key_settings
        end

        private

        def fetch_signing_key_settings
          if provider_uri_resource_exists? && !jwks_uri_has_resource_exists?
            SigningKeySettings.new(uri: fetch_provider_uri_signing_key,
                                   type: PROVIDER_URI_INTERFACE_NAME)
          elsif jwks_uri_has_resource_exists? && !provider_uri_resource_exists?
            SigningKeySettings.new(uri: fetch_jwks_uri_signing_key,
                                   type: JWKS_URI_INTERFACE_NAME)
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

        def fetch_provider_uri_signing_key
          @provider_uri_secret ||= @fetch_authenticator_secrets.call(
            conjur_account: @authenticator_input.account,
            authenticator_name: @authenticator_input.authenticator_name,
            service_id: @authenticator_input.service_id,
            required_variable_names: [PROVIDER_URI_RESOURCE_NAME]
          )[PROVIDER_URI_RESOURCE_NAME]
        end

        def fetch_jwks_uri_signing_key
          @jwks_uri_secret ||= @fetch_authenticator_secrets.call(
            conjur_account: @authenticator_input.account,
            authenticator_name: @authenticator_input.authenticator_name,
            service_id: @authenticator_input.service_id,
            required_variable_names: [JWKS_URI_RESOURCE_NAME]
          )[JWKS_URI_RESOURCE_NAME]
        end
      end
    end
  end
end
