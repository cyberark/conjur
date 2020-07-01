module Authentication
  module AuthnOidc

    Authenticator ||= CommandClass.new(
      dependencies: {
        enabled_authenticators:              Authentication::InstalledAuthenticators.enabled_authenticators_str(ENV),
        fetch_authenticator_secrets:         Authentication::Util::FetchAuthenticatorSecrets.new,
        token_factory:                       TokenFactory.new,
        validate_account_exists:             ::Authentication::Security::ValidateAccountExists.new,
        validate_webservice_is_whitelisted:  ::Authentication::Security::ValidateWebserviceIsWhitelisted.new,
        validate_role_can_access_webservice: ::Authentication::Security::ValidateRoleCanAccessWebservice.new,
        validate_origin:                     ValidateOrigin.new,
        audit_log:                           ::Audit.logger,
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
        add_username_to_input
        validate_webservice_is_whitelisted
        validate_user_has_access_to_webservice
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
        unless decoded_credentials.include?(id_token_field_name) &&
            !decoded_credentials[id_token_field_name].empty?
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
        if conjur_username.to_s.empty?
          raise Errors::Authentication::AuthnOidc::IdTokenFieldNotFoundOrEmpty,
                id_token_username_field
        end

        if admin?(conjur_username)
          raise Errors::Authentication::AuthnOidc::AdminAuthenticationDenied
        end

        @logger.debug(LogMessages::Authentication::AuthnOidc::ExtractedUsernameFromIDToked.new(conjur_username, id_token_username_field))
      end

      def conjur_username
        @conjur_username ||= @decoded_token[id_token_username_field]
      end

      def id_token_username_field
        oidc_authenticator_secrets["id-token-user-property"]
      end

      def validate_webservice_is_whitelisted
        @validate_webservice_is_whitelisted.(
          webservice: webservice,
          account: account,
          enabled_authenticators: @enabled_authenticators
        )
      end

      def validate_user_has_access_to_webservice
        @validate_role_can_access_webservice.(
          webservice: webservice,
          account: account,
          user_id: username,
          privilege: 'authenticate'
        )
      end

      def validate_origin
        @validate_origin.(
          account: account,
          username: username,
          client_ip: client_ip
        )
      end

      def audit_success
        @audit_log.log(
          ::Audit::Event::Authn::Authenticate.new(
            authenticator_name: authenticator_name,
            service: webservice,
            role_id: audit_role_id,
            client_ip: client_ip,
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
            role_id: audit_role_id,
            client_ip: client_ip,
            success: false,
            error_message: err.message
          )
        )
      end

      def audit_role_id
        ::Audit::Event::Authn::RoleId.new(
          role: role,
          account: account,
          username: username
        ).to_s
      end

      def admin?(username)
        username == "admin"
      end
    end

    class Authenticator
      # This delegates to all the work to the call method created automatically
      # by CommandClass
      #
      # This is needed because we need `valid?` to exist on the Authenticator
      # class, but that class contains only a metaprogramming generated
      # `call(authenticator_input:)` method.  The methods we define in the
      # block passed to `CommandClass` exist only on the private internal
      # `Call` objects created each time `call` is run.
      def valid?(input)
        call(authenticator_input: input)
      end

      def status(authenticator_status_input:)
        Authentication::AuthnOidc::ValidateStatus.new.(
          account: authenticator_status_input.account,
          service_id: authenticator_status_input.service_id
        )
      end
    end
  end
end
