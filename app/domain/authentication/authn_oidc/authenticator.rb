module Authentication
  module AuthnOidc

    class AuthenticationError < RuntimeError; end
    class NotFoundError < RuntimeError; end

    class Authenticator
      attr_reader :authenticator_name
      attr_reader :conjur_account
      attr_reader :service_id
      attr_reader :username

      def initialize(env:)
        @env = env
      end

      def valid?(input)
        # input has 5 attributes:
        #
        #     input.authenticator_name
        #     input.service_id
        #     input.account
        #     input.username
        #     input.password
        #

        @authenticator_name = input.authenticator_name
        @service_id = input.service_id
        @conjur_account = input.account
        @username = input.username

        verify_service_enabled

        authn_service = AuthenticationService.new(service.identifier, conjur_account)
        # todo: should we initialize only once?

        # todo: use authn service to authenticate user

        # return true until we have real authentication code
        true
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
