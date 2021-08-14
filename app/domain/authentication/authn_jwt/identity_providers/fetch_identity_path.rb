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
        inputs: %i[authentication_parameters]
      ) do

        def call
          fetch_identity_path
        end

        private

        def fetch_identity_path
          @logger.debug(LogMessages::Authentication::AuthnJwt::FetchingIdentityPath.new)
          set_identity_path_value
          @logger.info(LogMessages::Authentication::AuthnJwt::FetchedIdentityPath.new(@identity_path))
          @identity_path
        end

        def set_identity_path_value
          if identity_path_resource_exists?
            set_identity_path_from_policy
            @logger.info(
              LogMessages::Authentication::AuthnJwt::RetrievedResourceValue.new(
                identity_path_required_secret_value,
                IDENTITY_PATH_RESOURCE_NAME
              )
            )
          else
            set_identity_path_default_value
            @logger.debug(
              LogMessages::Authentication::AuthnJwt::IdentityPathNotConfigured.new(
                IDENTITY_PATH_RESOURCE_NAME
              )
            )
          end
        end

        def identity_path_resource_exists?
          return @identity_path_resource_exists unless @identity_path_resource_exists.nil?

          @identity_path_resource_exists ||= @check_authenticator_secret_exists.call(
            conjur_account: @authentication_parameters.account,
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
            var_name: IDENTITY_PATH_RESOURCE_NAME
          )
        end

        def set_identity_path_from_policy
          @identity_path = identity_path_required_secret_value
        end

        def identity_path_required_secret_value
          @identity_path_required_secret_value ||= @fetch_authenticator_secrets.call(
            conjur_account: @authentication_parameters.account,
            authenticator_name: @authentication_parameters.authenticator_name,
            service_id: @authentication_parameters.service_id,
            required_variable_names: [IDENTITY_PATH_RESOURCE_NAME]
          )[IDENTITY_PATH_RESOURCE_NAME]
        end

        def set_identity_path_default_value
          @identity_path = IDENTITY_PATH_DEFAULT_VALUE
        end
      end
    end
  end
end
