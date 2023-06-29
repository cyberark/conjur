module Authentication
  module AuthnOidc

    UpdateInputWithUsernameFromIdToken ||= CommandClass.new(
      dependencies: {
        fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
        validate_account_exists: ::Authentication::Security::ValidateAccountExists.new,
        verify_and_decode_token: ::Authentication::OAuth::VerifyAndDecodeToken.new,
        logger: Rails.logger
      },
      inputs: %i[authenticator_input]
    ) do
      extend(Forwardable)
      # The 'request' field in the 'authenticator_input' object will be used to extract the id token from the request header
      def_delegators(:@authenticator_input, :service_id, :authenticator_name,
                     :account, :username, :webservice, :credentials, :client_ip, :request,
                     :role)

      def call
        validate_account_exists
        validate_service_id_exists
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

      def validate_service_id_exists
        raise Errors::Authentication::AuthnOidc::ServiceIdMissing unless service_id
      end

      def verify_and_decode_token
        @decoded_token = @verify_and_decode_token.(
          provider_uri: oidc_authenticator_secrets["provider-uri"],
          token_jwt: decoded_credentials["id_token"],
          claims_to_verify: {} # We don't verify any claims
        )
      end

      # The credentials are in a URL encoded form data in the request body or in the request header
      def decoded_credentials
        @decoded_credentials ||= begin
          return token_from_body if token_from_body

          return token_from_header if token_from_header

          # If the token is not in the header or body, raise a missing param exception
          raise Errors::Authentication::RequestBody::MissingRequestParam, 'id_token'
        end
      end

      def token_from_header
        @token_from_header ||= begin
          return nil unless request&.headers&.key?("HTTP_AUTHORIZATION")

          # Extract the token from the authorization header
          id_token = request.headers['HTTP_AUTHORIZATION'].split(' ', -1)

          # Verify the token is given as a bearer token
          return nil unless id_token[0] == "Bearer" && id_token.length == 2

          # Return the token formatted as it would be if extracted from the body
          # as `application/x-www-form-urlencoded` data.
          {
            # URL decode the ID token from the header
            "id_token" => URI.decode_www_form_component(id_token[1])
          }
        end
      end

      def token_from_body
        @token_from_body ||= begin
          # Parse the request body
          credential_token = Hash[URI.decode_www_form(credentials)]

          # Return the parsed body if it include the token
          credential_token unless credential_token.fetch('id_token', "").empty?
        end
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
        @required_variable_names ||= %w[provider-uri id-token-user-property]
      end

      def validate_conjur_username
        if conjur_username.to_s.empty?
          raise Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty.new(
            id_token_username_field,
            "id-token-user-property"
          )
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
