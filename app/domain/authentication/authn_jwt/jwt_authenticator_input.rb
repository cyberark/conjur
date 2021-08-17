module Authentication
  module AuthnJwt
    # Data class to store data regarding jwt token that is needed during the jwt authentication process
    class JWTAuthenticatorInput
      attr_reader :authenticator_name, :service_id, :account, :username, :client_ip, :request, :decoded_token

      def initialize(authenticator_input:, decoded_token:)
        @authenticator_name = authenticator_input.authenticator_name
        @service_id = authenticator_input.service_id
        @account = authenticator_input.account
        @username = authenticator_input.username
        @client_ip = authenticator_input.client_ip
        @decoded_token = decoded_token
      end
    end
  end
end
