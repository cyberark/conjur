require 'command_class'

module Authentication
  module AuthnAzure

    Err = Errors::Authentication::AuthnAzure
    Log = LogMessages::Authentication::AuthnAzure
    # Possible Errors Raised:
    # TokenFieldNotFoundOrEmpty, MissingRequestParam

    Authenticator = CommandClass.new(
      dependencies: {
        fetch_authenticator_secrets:   Authentication::Util::FetchAuthenticatorSecrets.new,
        verify_and_decode_token:       Authentication::OAuth::VerifyAndDecodeToken.new,
        validate_application_identity: ValidateApplicationIdentity.new,
        logger:                        Rails.logger
      },
      inputs:       [:authenticator_input]
    ) do

      extend Forwardable
      def_delegators :@authenticator_input, :service_id, :authenticator_name, :account, :credentials, :username

      JWT_REQUEST_BODY_FIELD_NAME = "jwt".freeze
      XMS_MIRID_TOKEN_FIELD_NAME  = "xms_mirid".freeze
      OID_TOKEN_FIELD_NAME        = "oid".freeze

      def call
        validate_credentials_include_azure_token
        validate_azure_token
        validate_required_token_fields_exist
        validate_application_identity
      end

      private

      def validate_credentials_include_azure_token
        unless decoded_credentials.include?(JWT_REQUEST_BODY_FIELD_NAME) &&
            !decoded_credentials[JWT_REQUEST_BODY_FIELD_NAME].empty?
          raise Errors::Authentication::RequestBody::MissingRequestParam, JWT_REQUEST_BODY_FIELD_NAME
        end
      end

      # The credentials are in a URL encoded form data in the request body
      def decoded_credentials
        @decoded_credentials ||= Hash[URI.decode_www_form(credentials)]
      end

      def validate_azure_token
        decoded_token
      end

      def decoded_token
        @decoded_token ||= @verify_and_decode_token.call(
          provider_uri:     provider_uri,
          token_jwt:        decoded_credentials[JWT_REQUEST_BODY_FIELD_NAME],
          claims_to_verify: {
            verify_iss: true,
            iss:        provider_uri
          }
        )
      end

      def validate_application_identity
        @validate_application_identity.(
          service_id: service_id,
          account: account,
          username: username,
          xms_mirid_token_field: xms_mirid,
          oid_token_field: oid
        )
      end

      def provider_uri
        @provider_uri ||= azure_authenticator_secrets["provider-uri"].tap do |provider_uri_value|
          provider_uri_value << "/" unless provider_uri_value.end_with?('/')
        end
      end

      def azure_authenticator_secrets
        @azure_authenticator_secrets ||= @fetch_authenticator_secrets.(
          service_id: service_id,
          conjur_account: account,
          authenticator_name: authenticator_name,
          required_variable_names: required_variable_names
        )
      end

      def required_variable_names
        @required_variable_names ||= %w(provider-uri)
      end

      def validate_required_token_fields_exist
        validate_token_field_exists(XMS_MIRID_TOKEN_FIELD_NAME)
        validate_token_field_exists(OID_TOKEN_FIELD_NAME)
      end

      def validate_token_field_exists field_name
        @logger.debug(Log::ValidatingTokenFieldExists.new(field_name))
        raise Err::TokenFieldNotFoundOrEmpty, field_name if decoded_token[field_name].to_s.empty?
      end

      def xms_mirid
        token_field_value(XMS_MIRID_TOKEN_FIELD_NAME)
      end

      def oid
        token_field_value(OID_TOKEN_FIELD_NAME)
      end

      def token_field_value field_name
        decoded_token[field_name].tap do |token_field_value|
          @logger.debug(Log::ExtractedFieldFromAzureToken.new(field_name, token_field_value))
        end
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
        Authentication::AuthnAzure::ValidateStatus.new.(
          account: authenticator_status_input.account,
          service_id: authenticator_status_input.service_id
        )
      end
    end
  end
end
