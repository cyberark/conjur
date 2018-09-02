require 'uri'
require 'openid_connect'

module Authentication
  module AuthnOidc
    class OpenIdConnectAuthenticationError < RuntimeError; end

    class AuthenticationService
      attr_reader :service_id
      attr_reader :conjur_account

      # Constructs AuthenticationService from the <service-id>, which is typically something like
      # conjur/authn-oidc/<service-id>.
      def initialize service_id, conjur_account
        @service_id = service_id
        @conjur_account = conjur_account
      end

      # Retrieves an id token from the OpenIDConnect Provider and returns it decoded
      def get_user_details request_body
        request_body = URI.decode_www_form(request_body)
        @redirect_uri = request_body.assoc('redirect_uri').last
        authorization_code = request_body.assoc('code').last

        client = get_client
        client.authorization_code = authorization_code
        access_token = client.access_token!

        id_token = decode_id_token(access_token.id_token)
        user_info = access_token.userinfo!

        return id_token, user_info
        rescue => e
          raise OpenIdConnectAuthenticationError.new(e)
      end

      private

      def client_id
        Resource["#{conjur_account}:variable:#{service_id}/client-id"].secret.value
      end

      def client_secret
        Resource["#{conjur_account}:variable:#{service_id}/client-secret"].secret.value
      end

      def provider_uri
        Resource["#{conjur_account}:variable:#{service_id}/provider-uri"].secret.value
      end

      def redirect_uri
        @redirect_uri
      end

      def discover
        @discover ||= OpenIDConnect::Discovery::Provider::Config.discover! provider_uri
      end

      def get_client
        @client ||= OpenIDConnect::Client.new(
            identifier: client_id,
            secret: client_secret,
            redirect_uri: redirect_uri,
            token_endpoint: discover.token_endpoint,
            userinfo_endpoint: discover.userinfo_endpoint
        )
      end

      def decode_id_token id_token
        id_token = OpenIDConnect::ResponseObject::IdToken.decode id_token, discover.jwks
      end
    end
  end
end
