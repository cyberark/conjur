module Authentication
  module AuthnJwt
    # Data class to store data regarding jwt token that is needed during the jwt authentication process
    class AuthenticationParameters
      attr_accessor :decoded_token, :jwt_token
      attr_reader :authenticator_name, :service_id, :account, :username, :client_ip, :request

      def initialize(authentication_input:, jwt_token:)
        @authenticator_name = authentication_input.authenticator_name
        @service_id = authentication_input.service_id
        @account = authentication_input.account
        @username = authentication_input.username
        @client_ip = authentication_input.client_ip
        @request = authentication_input.request
        @jwt_token = jwt_token
      end

      def authenticator_resource_id
        "#{@account}:variable:conjur/#{@authenticator_name}/#{@service_id}"
      end
    end
  end
end
