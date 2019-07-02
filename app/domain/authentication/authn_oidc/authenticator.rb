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

      def status(account:, authenticator_name:, webservice:)
        Authentication::AuthnOidc::ValidateStatus.new.(
          account: account,
            service_id: webservice.service_id
        )
      end
    end
  end
end
