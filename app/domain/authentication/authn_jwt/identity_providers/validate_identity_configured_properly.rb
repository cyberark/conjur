require 'command_class'

module Authentication
  module AuthnJwt
    module IdentityProviders
      # This CommandClass is for the authenticator status check to check that if 'token-app-property' configured
      # so it is populated with secret and checks that if `identity-path` is configured it is also populated with
      # secret
      ValidateIdentityConfiguredProperly = CommandClass.new(
        dependencies: {
          fetch_identity_path: Authentication::AuthnJwt::IdentityProviders::FetchIdentityPath.new,
          fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new,
          logger: Rails.logger
        },
        inputs: %i[authentication_parameters]
      ) do
        def call
          validate_identity_configured_properly
        end

        private

        def validate_identity_configured_properly
          return unless identity_available?

          token_id_field_secret
          validate_identity_path_configured_properly
        end

        # Checks if variable that defined from which field in decoded token to get the id is configured
        def identity_available?
          return @identity_available if defined?(@identity_available)

          @identity_available = @check_authenticator_secret_exists.call(
            conjur_account: @authentication_parameters.account,
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
            var_name: TOKEN_APP_PROPERTY_VARIABLE
          )
        end

        def token_id_field_secret
          return @token_id_field_secret if @token_id_field_secret

          @token_id_field_secret = @fetch_authenticator_secrets.call(
            conjur_account: @authentication_parameters.account,
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
            required_variable_names: [TOKEN_APP_PROPERTY_VARIABLE]
          )[TOKEN_APP_PROPERTY_VARIABLE]
        end

        def validate_identity_path_configured_properly
          @fetch_identity_path.call(authentication_parameters: @authentication_parameters)
        end
      end
    end
  end
end
