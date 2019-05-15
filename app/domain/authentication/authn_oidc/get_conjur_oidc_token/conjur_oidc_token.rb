require 'command_class'

module Authentication
  module AuthnOidc
    module GetConjurOidcToken

      ConjurOidcToken = CommandClass.new(
        dependencies: {
          oidc_authenticator: AuthnOidc::GetConjurOidcToken::Authenticator.new,
          enabled_authenticators: ENV['CONJUR_AUTHENTICATORS'],
          fetch_oidc_secrets: AuthnOidc::Util::FetchOidcSecrets.new,
          oidc_client_class: ::Authentication::AuthnOidc::GetConjurOidcToken::Client,
          token_factory: OidcTokenFactory.new,
          validate_security: ::Authentication::Security::ValidateSecurity.new,
          validate_origin: ::Authentication::ValidateOrigin.new,
          audit_event: ::Authentication::AuditEvent.new
        },
        inputs: %i(authenticator_input)
      ) do

        def call
          fetch_id_token_details
          validate_credentials
          add_username_to_input
          validate_security
          validate_origin
          audit_success
          new_conjur_oidc_token
        rescue => e
          audit_failure(e)
          raise e
        end

        private

        def fetch_id_token_details
          oidc_id_token_details
        end

        def validate_credentials
          @oidc_authenticator.(input: @authenticator_input,
            oidc_id_token_details: oidc_id_token_details)
        end

        def add_username_to_input
          username = oidc_id_token_details.user_info.preferred_username
          @authenticator_input = @authenticator_input.update(username: username)
        end

        def oidc_id_token_details
          @oidc_id_token_details ||= oidc_client.oidc_id_token_details(request_body.authorization_code)
        end

        def oidc_client
          @oidc_client ||= @oidc_client_class.new(
            client_id: oidc_secrets["client-id"],
            client_secret: oidc_secrets["client-secret"],
            redirect_uri: request_body.redirect_uri,
            provider_uri: oidc_secrets["provider-uri"]
          )
        end

        def oidc_secrets
          @oidc_secrets ||= @fetch_oidc_secrets.(
            service_id: @authenticator_input.service_id,
              conjur_account: @authenticator_input.account,
              required_variable_names: required_variable_names
          )
        end

        def required_variable_names
          @required_variable_names ||= %w(client-id client-secret provider-uri)
        end

        def new_conjur_oidc_token
          @token_factory.oidc_token(oidc_id_token_details)
        end

        def request_body
          @request_body ||= AuthnOidc::GetConjurOidcToken::LoginRequestBody.new(@authenticator_input.request)
        end

        def validate_security
          @validate_security.(
            webservice: @authenticator_input.webservice,
              account: @authenticator_input.account,
              user_id: @authenticator_input.username,
              enabled_authenticators: @enabled_authenticators
          )
        end

        def validate_origin
          @validate_origin.(input: @authenticator_input)
        end

        def audit_success
          @audit_event.(input: @authenticator_input, success: true, message: nil)
        end

        def audit_failure(err)
          @audit_event.(input: @authenticator_input, success: false, message: err.message)
        end
      end
    end
  end
end
