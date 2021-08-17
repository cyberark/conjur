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
        inputs: %i[jwt_authenticator_input]
      ) do
        extend(Forwardable)
        def_delegators(:@jwt_authenticator_input, :service_id, :authenticator_name, :account)

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
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
            var_name: TOKEN_APP_PROPERTY_VARIABLE
          )
        end

        def token_id_field_secret
          return @token_id_field_secret if @token_id_field_secret

          @token_id_field_secret = @fetch_authenticator_secrets.call(
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
            required_variable_names: [TOKEN_APP_PROPERTY_VARIABLE]
          )[TOKEN_APP_PROPERTY_VARIABLE]
        end

        def validate_identity_path_configured_properly
          @fetch_identity_path.call(jwt_authenticator_input: @jwt_authenticator_input)
        end
      end
    end
  end
end
