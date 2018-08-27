module Authentication
  module AuthnOidc

    class Authenticator

      def initialize(env:)
        # initialization code based on ENV config
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
        @account = input.account

        verify_service_exists
        verify_service_enabled

        @username = input.username
        verify_user_exists
        verify_user_is_authorized_for_service

        # return true for valid credentials, false otherwise
        # we return true for now, untill we have real code
        true
      end

      def account
        @account
      end

      def authenticator_name
        @authenticator_name
      end

      def service_id
        @service_id
      end

      def service
        @service ||= Resource["#{account}:webservice:conjur/#{authenticator_name}/#{service_id}"]
      end

      def username
        @username
      end

      def user
        @user ||= Resource[username]
      end

      def verify_service_exists
        raise NotFoundError, "Service #{service_id} not found" if @service.nil?
      end

      def verify_service_enabled
        conjur_authenticators = (@env['CONJUR_AUTHENTICATORS'] || '').split(',').map(&:strip)
        unless conjur_authenticators.include?("#{authenticator_name}/#{service_id}")
          raise NotFoundError, "#{authenticator_name}/#{service_id} not whitelisted in CONJUR_AUTHENTICATORS"
        end
      end

      def verify_user_exists
        raise NotFoundError, "User #{username} not found" if user.nil?
      end

      def verify_user_is_authorized_for_service
        unless user.role.allowed_to?("authenticate", @service)
          raise AuthenticationError, "#{user.role.id} does not have 'authenticate' privilege on #{@service.id}"
        end
      end
    end
  end
end
