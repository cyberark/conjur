module Authentication
  module AuthnOidc

    # This class is a workaround so that authn-oidc will show in the
    # "installed authenticators"
    #
    # TODO: Change the way we define the installed authenticators so that
    # a change in design (such as the one that happened) will not break this
    #
    #
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
