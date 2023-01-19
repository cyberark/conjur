module Authentication
  module AuthnOidc

    UpdateInputWithUsernameFromIdToken ||= CommandClass.new(
      dependencies: {
        fetch_authenticator_secrets:         Authentication::Util::FetchAuthenticatorSecrets.new,
        validate_account_exists:             ::Authentication::Security::ValidateAccountExists.new,
        verify_and_decode_token:             ::Authentication::OAuth::VerifyAndDecodeToken.new,
        logger:                              Rails.logger
      },
      inputs:       %i(authenticator_input)
    ) do

      extend Forwardable
      def_delegators :@authenticator_input, :service_id, :authenticator_name,
                     :account, :username, :webservice, :credentials, :client_ip,
                     :role

      def call
        validate_account_exists
        validate_credentials_include_id_token
        verify_and_decode_token
        validate_conjur_username
        input_with_username
      end

      private

      def validate_account_exists
        @validate_account_exists.(
          account: account
        )
      end

      def validate_credentials_include_id_token
        id_token_field_name = "id_token"

        # check that id token field exists and has some value
        if decoded_credentials.fetch(id_token_field_name, "") == ""
          raise Errors::Authentication::RequestBody::MissingRequestParam, id_token_field_name
        end
      end

      def verify_and_decode_token
        @decoded_token = @verify_and_decode_token.(
          provider_uri: oidc_authenticator_secrets["provider-uri"],
          token_jwt: decoded_credentials["id_token"],
          claims_to_verify: {} # We don't verify any claims
        )
      end

      # The credentials are in a URL encoded form data in the request body
      def decoded_credentials
        @decoded_credentials ||= Hash[URI.decode_www_form(credentials)]
      end

      def oidc_authenticator_secrets
        @oidc_authenticator_secrets ||= @fetch_authenticator_secrets.(
          service_id: service_id,
          conjur_account: account,
          authenticator_name: authenticator_name,
          required_variable_names: required_variable_names
        )
      end

      def required_variable_names
        @required_variable_names ||= %w(provider-uri id-token-user-property)
      end

      def validate_conjur_username
        if conjur_username.to_s.empty?
          raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty,
                id_token_username_field
        end

        if conjur_username == "admin"
          raise Errors::Authentication::AdminAuthenticationDenied, authenticator_name
        end

        @logger.debug(
          LogMessages::Authentication::AuthnOidc::ExtractedUsernameFromIDToken.new(
            conjur_username,
            id_token_username_field
          )
        )
      end

      def conjur_username
        @decoded_token[id_token_username_field]
      end

      def id_token_username_field
        oidc_authenticator_secrets["id-token-user-property"]
      end

      def input_with_username
        @authenticator_input.update(username: conjur_username)
      end
    end
  end
end
