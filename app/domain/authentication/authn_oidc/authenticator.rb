module Authentication
  module AuthnOidc
    class AuthenticationError < RuntimeError; end
    class NotFoundError < RuntimeError; end
    class OIDCConfigurationError < RuntimeError; end
    class OIDCAuthenticationError < RuntimeError; end

    class Authenticator

      def initialize(env:)
        @env = env
      end

      def valid?(input)
        @authenticator_name = input.authenticator_name
        @service_id = input.service_id
        @conjur_account = input.account
        @request_body = input.request.body.read

        verify_service_enabled

        oidc_authn_service = AuthenticationService.new(service.identifier, @conjur_account)
        user_details = oidc_authn_service.user_details(@request_body)

        # validate id_token claims - if not raise error
        validate_id_token_claims(user_details.id_token, oidc_authn_service.client_id, oidc_authn_service.issuer)

        validate_user_info(user_details.user_info, user_details.id_token.sub)

        username = user_details.user_info.preferred_username
        input.instance_variable_set(:@username, username)

        true
      end

      private

      def service
        @service ||= Resource["#{@conjur_account}:webservice:conjur/#{@authenticator_name}/#{@service_id}"]
      end

      def verify_service_enabled
        verify_service_exist

        conjur_authenticators = (@env['CONJUR_AUTHENTICATORS'] || '').split(',').map(&:strip)

        raise OIDCConfigurationError, "#{@authenticator_name}/#{@service_id} not whitelisted in CONJUR_AUTHENTICATORS" unless authenticator_available?
      end

      def verify_service_exist
        raise OIDCConfigurationError, "Webservice [conjur/#{@authenticator_name}/#{@service_id}] not found in Conjur" unless service
      end

      def validate_id_token_claims(id_token, client_id, issuer)
        expected = { client_id: client_id, issuer: issuer } # , nonce: 'nonce'}
        id_token.verify! expected
      end

      def validate_user_info(user_info, id_token_subject)
        unless user_info.sub == id_token_subject
          raise OIDCAuthenticationError, "User info subject [#{user_info.sub}] and id token subject [#{id_token_subject}] are not equal"
        end

        # validate user_info was included in scope
        if user_info.preferred_username.nil?
          raise OIDCAuthenticationError, "[profile] is not included in scope of authorization code request"
        end
      end

      def authenticator_available?
        conjur_authenticators.include?("#{@authenticator_name}/#{@service_id}")
      end
    end
  end
end
