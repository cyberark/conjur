module Authentication
  module AuthnOidc
    class AuthenticationService
      attr_reader :service_id
      attr_reader :conjur_account

      # Constructs AuthenticationService from the <service-id>, which is typically something like
      # conjur/authn-oidc/<service-id>.
      def initialize service_id, conjur_account
        @service_id = service_id
        @conjur_account = conjur_account
      end

      def client_id_variable
        Resource["#{conjur_account}:variable:#{service_id}/client-id"]
      end

      def client_secret_variable
        Resource["#{conjur_account}:variable:#{service_id}/client-secret"]
      end

      def provider_uri_variable
        Resource["#{conjur_account}:variable:#{service_id}/provider-uri"]
      end
    end
  end
end
