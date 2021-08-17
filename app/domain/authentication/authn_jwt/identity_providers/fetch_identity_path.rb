require 'command_class'

module Authentication
  module AuthnJwt
    module IdentityProviders
      # Fetch the identity path from the JWT authenticator policy of the host identity
      FetchIdentityPath = CommandClass.new(
        dependencies: {
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new,
          fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
          logger: Rails.logger
        },
        inputs: %i[jwt_authenticator_input]
      ) do
        extend(Forwardable)
        def_delegators(:@jwt_authenticator_input, :service_id, :authenticator_name, :account)

        def call
          fetch_identity_path
        end

        private

        def fetch_identity_path
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingIdentityPath.new)
          identity_path
        end

        def identity_path
          return @identity_path if @identity_path

          if identity_path_resource_exists?
            @logger.info(
              LogMessages::Authentication::AuthnJwt::RetrievedResourceValue.new(
                identity_path_secret_value,
                IDENTITY_PATH_RESOURCE_NAME
              )
            )
            @identity_path = identity_path_secret_value
          else
            @logger.debug(
              LogMessages::Authentication::AuthnJwt::IdentityPathNotConfigured.new(
                IDENTITY_PATH_RESOURCE_NAME
              )
            )
            @identity_path = IDENTITY_PATH_DEFAULT_VALUE
          end

          @logger.info(LogMessages::Authentication::AuthnJwt::FetchedIdentityPath.new(@identity_path))
          @identity_path
        end

        def identity_path_resource_exists?
          return @identity_path_resource_exists if defined?(@identity_path_resource_exists)

          @identity_path_resource_exists ||= @check_authenticator_secret_exists.call(
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
            var_name: IDENTITY_PATH_RESOURCE_NAME
          )
        end

        def identity_path_secret_value
          @identity_path_secret_value ||= @fetch_authenticator_secrets.call(
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: ervice_id,
            required_variable_names: [IDENTITY_PATH_RESOURCE_NAME]
          )[IDENTITY_PATH_RESOURCE_NAME]
        end
      end
    end
  end
end
