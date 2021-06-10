require 'command_class'

module Authentication
  module AuthnJwt
    module IdentityProviders
      # Fetch the identity path from the JWT authenticator policy of the host identity
      FetchIdentityPath = CommandClass.new(
        dependencies: {
          resource_class: ::Resource,
          fetch_required_secrets: ::Conjur::FetchRequiredSecrets.new,
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
          validate_configuration_and_set_identity_path_value
          @logger.info(LogMessages::Authentication::AuthnJwt::FetchedIdentityPath.new(identity_path))
          identity_path
        end

        def validate_configuration_and_set_identity_path_value
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatingIdentityPathConfiguration.new)
          if identity_path_resource_exists?
            set_identity_path_from_policy
            @logger.info(
              LogMessages::Authentication::AuthnJwt::RetrievedResourceValue.new(
                identity_path_required_secret_value,
                identity_path_resource_id))
          else
            set_identity_path_default_value
            @logger.debug(
              LogMessages::Authentication::AuthnJwt::IdentityPathNotConfigured.new(
                identity_path_resource_id
              )
            )
          end
          @logger.debug(LogMessages::Authentication::AuthnJwt::ValidatedIdentityPathConfiguration.new)
        end

        def identity_path_resource_exists?
          return @identity_path_resource_exists unless @identity_path_resource_exists.nil?
          @identity_path_resource_exists ||= !identity_path_resource.nil?
        end

        def identity_path_resource
          @identity_path_resource ||= @resource_class[identity_path_resource_id]
        end

        def identity_path_resource_id
          @identity_path_resource_id ||= "#{@authentication_parameters.authn_jwt_variable_id}/#{IDENTITY_PATH_RESOURCE_NAME}"
        end

        def set_identity_path_from_policy
          @identity_path = identity_path_required_secret_value
        end

        def identity_path_required_secret_value
          @identity_path_required_secret_value ||= identity_path_required_secret[identity_path_resource_id]
        end

        def identity_path_required_secret
          @identity_path_required_secret ||= @fetch_required_secrets.(resource_ids: [identity_path_resource_id])
        end

        def set_identity_path_default_value
          @identity_path = IDENTITY_PATH_DEFAULT_VALUE
        end

        def identity_path
          @identity_path
        end
      end
    end
  end
end
