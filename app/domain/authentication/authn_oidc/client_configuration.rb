module Authentication
  module AuthnOidc
    class ClientConfiguration
      attr_reader :client_id, :client_secret, :redirect_uri, :provider_uri, :id_token_user_property

      def initialize(client_id:, client_secret:, redirect_uri:, provider_uri:, id_token_user_property:)
        @client_id = client_id
        @client_secret = client_secret
        @redirect_uri = redirect_uri
        @provider_uri = provider_uri
        @id_token_user_property = id_token_user_property
      end
    end
  end
end
