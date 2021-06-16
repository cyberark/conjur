module Authentication
  module AuthnJwt
    module IdentityProviders
      # Class for providing jwt identity from the decoded token from the field specified in a secret
      class IdentityFromDecodedTokenProvider < IdentityProviderInterface
        def initialize(
          authentication_parameters:,
          fetch_required_secrets: Conjur::FetchRequiredSecrets.new,
          resource_class: ::Resource,
          fetch_identity_path: Authentication::AuthnJwt::IdentityProviders::FetchIdentityPath.new,
          add_prefix_to_identity: Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new,
          logger: Rails.logger
        )
          @logger = logger
          @fetch_required_secrets = fetch_required_secrets
          @resource_class = resource_class
          @fetch_identity_path = fetch_identity_path
          @add_prefix_to_identity = add_prefix_to_identity

          @authentication_parameters = authentication_parameters
        end

        def jwt_identity
          @logger.debug(
            LogMessages::Authentication::AuthnJwt::FetchingIdentityByInterface.new(
              TOKEN_IDENTITY_PROVIDER_INTERFACE_NAME
            )
          )
          fetch_identity_name_from_token
          fetch_identity_path
          add_prefix_path_to_identity_name
          add_host_to_identity_with_prefix
          @logger.info(
            LogMessages::Authentication::AuthnJwt::FetchedIdentityByInterface.new(
              host_identity_with_prefix,
              TOKEN_IDENTITY_PROVIDER_INTERFACE_NAME
            )
          )

          host_identity_with_prefix
        end

        # Checks if variable that defined from which field in decoded token to get the id is configured
        def identity_available?
          return @identity_available if defined?(@identity_available)

          @identity_available = token_id_field_variable.present?
        end

        # This method is for the authenticator status check, unlike 'identity_available?' it checks also:
        # 1. token-app-property secret value is not empty
        # 2. identity-path secret value is not empty (resource not exists is ok)
        def validate_identity_configured_properly
          return unless identity_available?

          validate_token_id_field_has_value
          validate_identity_path_configured_properly
        end

        private

        def fetch_identity_name_from_token
          return @identity_name_from_token if @identity_name_from_token

          @logger.debug(LogMessages::Authentication::AuthnJwt::CheckingIdentityFieldExists.new(token_id_field_secret))
          @identity_name_from_token = decoded_token[token_id_field_secret]
          if @identity_name_from_token.blank?
            raise Errors::Authentication::AuthnJwt::NoSuchFieldInToken, token_id_field_secret
          end

          @logger.debug(
            LogMessages::Authentication::AuthnJwt::FoundJwtFieldInToken.new(
              token_id_field_secret,
              @identity_name_from_token
            )
          )
          @identity_name_from_token
        end

        def token_id_field_secret
          return @token_id_field_secret if @token_id_field_secret

          @token_id_field_secret = @fetch_required_secrets.call(
            resource_ids: [token_id_field_variable_id]
          )[token_id_field_variable_id]

          @logger.info(
            LogMessages::Authentication::AuthnJwt::RetrievedResourceValue.new(
              @token_id_field_secret,
              token_id_field_variable_id
            )
          )
          @token_id_field_secret
        end

        def token_id_field_variable_id
          @token_id_field_variable_id ||= "#{@authentication_parameters.authn_jwt_variable_id_prefix}/#{TOKEN_APP_PROPERTY_VARIABLE}"
        end

        def decoded_token
          @authentication_parameters.decoded_token
        end

        def token_id_field_variable
          @token_id_field_variable ||= @resource_class[token_id_field_variable_id]
        end

        def fetch_identity_path
          identity_path
        end

        def identity_path
          @identity_path ||= @fetch_identity_path.call(authentication_parameters: @authentication_parameters)
        end

        def identity_name_from_token
          @identity_name_from_token || fetch_identity_name_from_token
        end

        def add_prefix_path_to_identity_name
          @add_prefix_path_to_identity_name ||=
            if identity_path.blank?
              identity_name_from_token
            else
              @add_prefix_to_identity.call(
                identity_prefix: identity_path,
                identity: identity_name_from_token
              )
            end
        end

        def identity_name_with_prefix_path
          @identity_name_with_prefix_path ||= add_prefix_path_to_identity_name
        end

        def add_host_to_identity_with_prefix
          host_identity_with_prefix
        end

        def host_identity_with_prefix
          @host_identity_with_prefix ||=
            @add_prefix_to_identity.call(
              identity_prefix: IDENTITY_TYPE_HOST,
              identity: identity_name_with_prefix_path
            )
        end

        def validate_token_id_field_has_value
          @fetch_required_secrets.call(resource_ids: [token_id_field_variable_id])[token_id_field_variable_id]
        end

        def validate_identity_path_configured_properly
          @fetch_identity_path.call(authentication_parameters: @authentication_parameters)
        end
      end
    end
  end
end
