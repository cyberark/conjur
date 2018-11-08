module Authentication
  module AuthnOidc
    class OidcClientConfiguration
      attr_reader :client_id, :client_secret, :redirect_uri, :provider_uri

      def initialize(client_id:, client_secret:, redirect_uri:, provider_uri:)
        @client_id = client_id
        @client_secret = client_secret
        @redirect_uri = redirect_uri
        @provider_uri = provider_uri
      end
    end
  end
end
