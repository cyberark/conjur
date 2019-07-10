module Authentication
  module AuthnOidc
    class Authenticator

      def initialize(env:)
        @env = env
      end

      def valid?
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
