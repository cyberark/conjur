require 'command_class'

module Authentication
  module AuthnOidc

    Log = LogMessages::Authentication::AuthnOidc
    Err = Errors::Authentication::AuthnOidc
    # Possible Errors Raised:
    # IdTokenFieldNotFoundOrEmpty, AdminAuthenticationDenied

    Authenticate = CommandClass.new(
      dependencies: {
        enabled_authenticators:     ENV['CONJUR_AUTHENTICATORS'],
        fetch_oidc_secrets:         AuthnOidc::Util::FetchOidcSecrets.new,
        token_factory:              TokenFactory.new,
        validate_security:          ::Authentication::Security::ValidateSecurity.new,
        validate_origin:            ValidateOrigin.new,
        audit_event:                AuditEvent.new,
        decode_and_verify_id_token: DecodeAndVerifyIdToken.new,
        logger:                     Rails.logger
      },
      inputs:       %i(authenticator_input)
    ) do

      def call
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

      def decode_and_verify_id_token
        @id_token_attributes = @decode_and_verify_id_token.(
          provider_uri: oidc_secrets["provider-uri"],
            id_token_jwt: request_body.id_token
        )
      end

      def add_username_to_input
        @authenticator_input = @authenticator_input.update(username: conjur_username)
      end

      def request_body
        @request_body ||= AuthnOidc::AuthenticateRequestBody.new(@authenticator_input.request)
      end

      def oidc_secrets
        @oidc_secrets ||= @fetch_oidc_secrets.(
          service_id: @authenticator_input.service_id,
          conjur_account: @authenticator_input.account,
          required_variable_names: required_variable_names,
        )
      end

      def required_variable_names
        @required_variable_names ||= %w(provider-uri id-token-user-property role-type)
      end

      def new_token
        @token_factory.signed_token(
          account:  @authenticator_input.account,
          username: @authenticator_input.username
        )
      end

      def validate_conjur_username
        for field in id_token_username_fields do
          if @id_token_attributes[field].to_s.empty?
            raise Err::IdTokenFieldNotFoundOrEmpty, field
          end
        end

        raise Err::AdminAuthenticationDenied if admin?(conjur_username)

        @logger.debug(Log::ExtractedUsernameFromIDToked.new(conjur_username, id_token_username_fields))
      end

      def conjur_username
        @conjur_username ||= begin
          role_type + id_token_username_fields.map{ |field| \
                                         @id_token_attributes[field] }.join('/')
        end
      end

      def role_type
        @role_type ||= begin
          if oidc_secrets.key?("role-type")
            oidc_secrets["role-type"] + "/"
          else
            ""
          end
        end
      end

      def id_token_username_fields
        oidc_secrets["id-token-user-property"].split(",").compact.collect(&:strip)
      end

      def validate_security
        @validate_security.(
          webservice: @authenticator_input.webservice,
            account: @authenticator_input.account,
            user_id: @authenticator_input.username,
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
