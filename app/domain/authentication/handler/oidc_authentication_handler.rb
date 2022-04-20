module Authentication
  module Handler
    class OidcAuthenticationHandler < AuthenticationHandler
      def generate_login_url(authenticator)
        params = {
          client_id: authenticator.client_id,
          response_type: authenticator.response_type,
          scope: ERB::Util.url_encode(authenticator.scope),
          state: authenticator.state,
          nonce: authenticator.nonce,
        }.map { |key, value| "#{key}=#{value}" }.join("&")

        return "#{discovery_information.authorization_endpoint}?#{params}"

      end

      protected

      def validate_payload_is_valid(authenticator, payload)
        super.validate_payload_is_valid(authenticator, payload)

        raise "State Mismatch" unless payload[:state] == authenticator.state
      end

      def extract_identity(authenticator, payload)
        client.authorization_code = params[:code]
        id_token = client.access_token!(
          scope: true,
          client_auth_method: :basic
        ).id_token

        decoded_id_token = ::OpenIDConnect::ResponseObject::IdToken.decode(
          id_token,
          discovery_information.jwks
        )

        decoded_id_token.verify!(
          issuer: authenticator.provider_uri,
          client_id: authenticator.client_id,
          nonce: authenticator.nonce
        )

        return decoded_id_token.raw_attributes[authenticator.claim_mapping]
      end

      def type
        return 'oidc'
      end

      def discovery_information(authenticator, provider_uri)
        Rails.cache.fetch("#{authenticator.account}/#{authenticator.service_id}/provider_uri",
                          expires_in: 5.min) do
          ::OpenIDConnect::Discovery::Provider::Config.discover!(provider_uri)
        end
      end

      def client(authenticator)
        @client ||= begin
          issuer_uri = URI(authenticator.provider_uri)
          ::OpenIDConnect::Client.new(
            identifier: authenticator.client_id,
            secret: authenticator.client_secret,
            redirect_uri: authenticator.redirect_uri,
            scheme: issuer_uri.scheme,
            host: issuer_uri.host,
            port: issuer_uri.port,
            authorization_endpoint: URI(discovery_information.authorization_endpoint).path,
            token_endpoint: URI(discovery_information.token_endpoint).path,
            userinfo_endpoint: URI(discovery_information.userinfo_endpoint).path,
            jwks_uri: URI(discovery_information.jwks_uri).path,
            end_session_endpoint: URI(discovery_information.end_session_endpoint).path
          )
        end
      end
    end
  end
end