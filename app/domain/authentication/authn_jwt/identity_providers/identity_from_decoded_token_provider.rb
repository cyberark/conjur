require 'command_class'

module Authentication
  module AuthnJwt
    module IdentityProviders
      # Command Class for providing jwt identity from the decoded token from the field specified in a secret
      IdentityFromDecodedTokenProvider = CommandClass.new(
        dependencies: {
          fetch_identity_path: Authentication::AuthnJwt::IdentityProviders::FetchIdentityPath.new,
          fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
          check_authenticator_secret_exists: Authentication::Util::CheckAuthenticatorSecretExists.new,
          add_prefix_to_identity: Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new,
          logger: Rails.logger
        },
        inputs: %i[jwt_authenticator_input]
      ) do
        extend(Forwardable)
        def_delegators(:@jwt_authenticator_input, :service_id, :authenticator_name, :account)

        def call
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

          @token_id_field_secret = @fetch_authenticator_secrets.call(
            conjur_account: account,
            authenticator_name: authenticator_name,
            service_id: service_id,
            required_variable_names: [TOKEN_APP_PROPERTY_VARIABLE]
          )[TOKEN_APP_PROPERTY_VARIABLE]
        end

        def decoded_token
          @jwt_authenticator_input.decoded_token
        end

        def fetch_identity_path
          identity_path
        end

        def identity_path
          @identity_path ||= @fetch_identity_path.call(jwt_authenticator_input: @jwt_authenticator_input)
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
      end
    end
  end
end
