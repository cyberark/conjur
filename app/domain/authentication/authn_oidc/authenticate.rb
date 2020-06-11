require 'command_class'

module Authentication
  module AuthnOidc

    Log ||= LogMessages::Authentication::AuthnOidc
    Err ||= Errors::Authentication::AuthnOidc
    # Possible Errors Raised:
    # IdTokenFieldNotFoundOrEmpty, AdminAuthenticationDenied

    # TODO: Changing the = below to ||= causes an unitialized constant.  I 
    # was never able to figure out why, but it would be worth investigating.
    # Even better, figure out how to make all these classes play nice with 
    # Rails auto-loading to the ||= hack isn't needed to prevent "constant
    # already defined" errors.
    #
    Authenticate = CommandClass.new(
      dependencies: {
        enabled_authenticators:      Authentication::InstalledAuthenticators.enabled_authenticators_str(ENV),
        fetch_authenticator_secrets: Authentication::Util::FetchAuthenticatorSecrets.new,
        token_factory:               TokenFactory.new,
        validate_account_exists:     ::Authentication::Security::ValidateAccountExists.new,
        validate_security:           ::Authentication::Security::ValidateSecurity.new,
        validate_origin:             ValidateOrigin.new,
        audit_log:                   ::Audit.logger,
        verify_and_decode_token:     ::Authentication::OAuth::VerifyAndDecodeToken.new,
        logger:                      Rails.logger
      },
      inputs:       %i(authenticator_input)
    ) do

      extend Forwardable
      def_delegators :@authenticator_input, :service_id, :authenticator_name, :account, :username, :webservice, :credentials, :origin, :role

      def call
        validate_account_exists
        validate_credentials_include_id_token
        verify_and_decode_token
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

      def validate_credentials_include_id_token
        id_token_field_name = "id_token"

        # check that id token field exists and has some value
        raise Errors::Authentication::RequestBody::MissingRequestParam, id_token_field_name unless decoded_credentials.include?(id_token_field_name) &&
          !decoded_credentials[id_token_field_name].empty?
      end

      def verify_and_decode_token
        @decoded_token = @verify_and_decode_token.(
          provider_uri: oidc_authenticator_secrets["provider-uri"],
          token_jwt: decoded_credentials["id_token"],
          claims_to_verify: {} # We don't verify any claims
        )
      end

      def add_username_to_input
        @authenticator_input = @authenticator_input.update(username: conjur_username)
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
        @conjur_username ||= @decoded_token[id_token_username_field]
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
        @validate_origin.(
          account: account,
          username: username,
          origin: origin
        )
      end

      def audit_success
        @audit_log.log(
          ::Audit::Event::Authn::Authenticate.new(
            authenticator_name: authenticator_name,
            service: webservice,
            role: role,
            success: true,
            error_message: nil
          )
        )
      end

      def audit_failure(err)
        @audit_log.log(
          ::Audit::Event::Authn::Authenticate.new(
            authenticator_name: authenticator_name,
            service: webservice,
            role: role,
            success: false,
            error_message: err.message
          )
        )
      end

      def admin?(username)
        username == "admin"
      end
    end
  end
end
