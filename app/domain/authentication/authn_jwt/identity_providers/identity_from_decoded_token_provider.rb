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
          logger: Rails.logger
        },
        inputs: %i[jwt_authenticator_input]
      ) do
        def call
          @logger.debug(
            LogMessages::Authentication::AuthnJwt::FetchingIdentityByInterface.new(
              TOKEN_IDENTITY_PROVIDER_INTERFACE_NAME
            )
          )

          # Ensures token has id claim, and stores its value in @id_from_token.
          fetch_id_from_token

          # Get value of "identity-path", which is stored as a Conjur secret.
          id_path = @fetch_identity_path.call(
            jwt_authenticator_input: @jwt_authenticator_input
          )

          # Create final id by joining "host", <path>, and <id>.
          host_prefix = IDENTITY_TYPE_HOST

          # File.join handles duplicate `/` for us.  Eg:
          #     File.join('/a/b/', '/c/d/', '/e') => "/a/b/c/d/e"
          full_host_id = File.join(host_prefix, id_path, @id_from_token)

          @logger.info(
            LogMessages::Authentication::AuthnJwt::FetchedIdentityByInterface.new(
              full_host_id,
              TOKEN_IDENTITY_PROVIDER_INTERFACE_NAME
            )
          )

          full_host_id
        end

        private

        def fetch_id_from_token
          return @id_from_token if @id_from_token

          @logger.debug(
            LogMessages::Authentication::AuthnJwt::CheckingIdentityFieldExists.new(id_claim_key)
          )

          raw_token = @jwt_authenticator_input.decoded_token[id_claim_key]

          # Converts nil to empty string.
          @id_from_token = String(raw_token).strip

          if @id_from_token.empty?
            raise Errors::Authentication::AuthnJwt::NoSuchFieldInToken, id_claim_key
          end

          @logger.debug(
            LogMessages::Authentication::AuthnJwt::FoundJwtFieldInToken.new(
              id_claim_key,
              @id_from_token
            )
          )

          @id_from_token
        end

        # The identity claim has a key and a value.  The key's name is stored
        # as a Conjur secret called 'token-app-property'.
        def id_claim_key
          return @id_claim_key if @id_claim_key

          @id_claim_key = @fetch_authenticator_secrets.call(
            conjur_account: @jwt_authenticator_input.account,
            authenticator_name: @jwt_authenticator_input.authenticator_name,
            service_id: @jwt_authenticator_input.service_id,
            required_variable_names: [TOKEN_APP_PROPERTY_VARIABLE]
          )[TOKEN_APP_PROPERTY_VARIABLE]
        end
      end
    end
  end
end
