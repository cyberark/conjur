require 'command_class'

module Authentication
  module AuthnOidc

    Log = LogMessages::Authentication::AuthnOidc
    Err = Errors::Authentication::AuthnOidc
    # Possible Errors Raised:
    # IdTokenFieldNotFoundOrEmpty, AdminAuthenticationDenied

    Authenticate = CommandClass.new(
      dependencies: {
        enabled_authenticators:      Authentication::InstalledAuthenticators.enabled_authenticators_str(ENV),
        fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
        token_factory:               TokenFactory.new,
        validate_account_exists:     ::Authentication::Security::ValidateAccountExists.new,
        validate_security:           ::Authentication::Security::ValidateSecurity.new,
        validate_origin:             ValidateOrigin.new,
        audit_event:                 AuditEvent.new,
        decode_and_verify_id_token:  DecodeAndVerifyIdToken.new,
        logger:                      Rails.logger
      },
      inputs:       %i(authenticator_input)
    ) do

      extend Forwardable
      def_delegators :@authenticator_input, :service_id, :authenticator_name, :account, :username, :request, :webservice

      def call
        validate_account_exists
        decode_and_verify_id_token
        validate_conjur_username
        add_username_to_input
        validate_security
        validate_origin
        audit_success
        new_token
      rescue => e
        audit_failure(e)
        raise e
      end

      private

      def validate_account_exists
        @validate_account_exists.(
          account: account
        )
      end

      def decode_and_verify_id_token
        @id_token_attributes = @decode_and_verify_id_token.(
          provider_uri: oidc_authenticator_secrets["provider-uri"],
            id_token_jwt: request_body.id_token
        )
      end

      def add_username_to_input
        @authenticator_input = @authenticator_input.update(username: conjur_username)
      end

      def request_body
        @request_body ||= AuthnOidc::AuthenticateRequestBody.new(request)
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

      def new_token
        @token_factory.signed_token(
          account:  account,
          username: username
        )
      end

      def validate_conjur_username
        raise Err::IdTokenFieldNotFoundOrEmpty, id_token_username_field if conjur_username.to_s.empty?
        raise Err::AdminAuthenticationDenied if admin?(conjur_username)
        @logger.debug(Log::ExtractedUsernameFromIDToked.new(conjur_username, id_token_username_field))
      end

      def conjur_username
        @conjur_username ||= @id_token_attributes[id_token_username_field]
      end

      def id_token_username_field
        oidc_authenticator_secrets["id-token-user-property"]
      end

      def validate_security
        @validate_security.(
          webservice: webservice,
            account: account,
            user_id: username,
            enabled_authenticators: @enabled_authenticators
        )

        @logger.debug(LogMessages::Authentication::Security::SecurityValidated.new.to_s)
      end

      def validate_origin
        @validate_origin.(input: @authenticator_input)
        @logger.debug(LogMessages::Authentication::OriginValidated.new.to_s)
      end

      def audit_success
        @audit_event.(
          authenticator_input: @authenticator_input,
            success: true,
            message: nil
        )
      end

      def audit_failure(err)
        @audit_event.(
          authenticator_input: @authenticator_input,
            success: false,
            message: err.message
        )
      end

      def admin?(username)
        username == "admin"
      end
    end
  end
end
