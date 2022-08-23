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
      def_delegators(:@authenticator_input, :service_id, :authenticator_name,
                     :account, :username, :webservice, :credentials, :client_ip, :request,
                     :role)

      def call
        validate_account_exists
        validate_service_id_exists
        validate_credentials_include_id_token
        verify_and_decode_token
        validate_conjur_username
        input_with_username
      end

      def initialize()
        @dec_cred = 'NA'
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

      def validate_credentials_include_id_token
        Rails.logger.info("+++++++++ validate_credentials_include_id_token 1")

        #request.headers.each { |key, value|  Rails.logger.info("+++++++++ validate_credentials_include_id_token 4 key = #{key} value = #{value}")}

        id_token_field_name = "id_token"
        @dec_cred = decoded_credentials

        # check that id token field exists and has some value
        if @dec_cred.fetch(id_token_field_name, "") == ""

          Rails.logger.info("+++++++++ validate_credentials_include_id_token 2")
          idToken = request.headers["HTTP_AUTHORIZATION"].split(' ', -1)
          Rails.logger.info("+++++++++ validate_credentials_include_id_token 3 idToken[0]=#{idToken[0]}")
          if idToken.empty? || idToken[0] != "Bearer"
            raise Errors::Authentication::RequestBody::MissingRequestParam, id_token_field_name
          end

          Rails.logger.info("+++++++++ validate_credentials_include_id_token 4 idToken = #{idToken[1]}")
          @dec_cred = Hash[URI.decode_www_form("id_token=" + idToken[1])]
          Rails.logger.info("+++++++++ validate_credentials_include_id_token 7 @dec_cred = #{@dec_cred}")

        end
      end

      def verify_and_decode_token
        Rails.logger.info("+++++++++ verify_and_decode_token 1 @dec_cred = #{@dec_cred}")
        @decoded_token = @verify_and_decode_token.(
          provider_uri: oidc_authenticator_secrets["provider-uri"],
          token_jwt: @dec_cred["id_token"], #decoded_credentials["id_token"],
          claims_to_verify: {} # We don't verify any claims
        )
        Rails.logger.info("+++++++++ verify_and_decode_token 2")
      end

      # The credentials are in a URL encoded form data in the request body
      def decoded_credentials
        Rails.logger.info("+++++++++ decoded_credentials credentials = #{credentials}")
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
        @required_variable_names ||= %w[provider-uri id-token-user-property] # id-token-prefix]
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

      def id_token_prefix_field
        oidc_authenticator_secrets["id-token-prefix"]
      end

      def input_with_username
        @authenticator_input.update(username: conjur_username)
      end
    end
  end
end
