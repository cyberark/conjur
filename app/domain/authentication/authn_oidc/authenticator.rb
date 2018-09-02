module Authentication
  module AuthnOidc

    class AuthenticationError < RuntimeError; end
    class NotFoundError < RuntimeError; end
    class OpenIdConnectAuthenticationError < RuntimeError; end

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

        oidc_authn_service = AuthenticationService.new(service.identifier, conjur_account)
        id_token, user_info = oidc_authn_service.get_user_details(request_body)

        # TODO: validate id_token - if not raise error

        # validate user_info
        unless id_token.sub == user_info.sub
          raise OpenIdConnectAuthenticationError, "User info subject and id token subject are not equal"
        end

        username = user_info.preferred_username

        # TODO: remove hardcode 'alice' once we have an oidc container
        input.instance_variable_set(:@username, 'alice')
        true
      end

      private

      def authenticator_name
        @authenticator_name
      end

      def conjur_account
        @conjur_account
      end

      def service_id
        @service_id
      end

      def request_body
        @request_body
      end

      def service
        @service ||= Resource["#{conjur_account}:webservice:conjur/#{authenticator_name}/#{service_id}"]
      end

      def user
        @user ||= Resource["#{conjur_account}:user:#{username}"]
      end

      def verify_service_enabled
        conjur_authenticators = (@env['CONJUR_AUTHENTICATORS'] || '').split(',').map(&:strip)
        unless conjur_authenticators.include?("#{authenticator_name}/#{service_id}")
          raise NotFoundError, "#{authenticator_name}/#{service_id} not whitelisted in CONJUR_AUTHENTICATORS"
        end
      end
    end
  end
end
