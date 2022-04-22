require 'openid_connect'

module Authentication
  module Util
    class OidcUtil
      def initialize(authenticator:)
        @authenticator = authenticator
      end

      def discovery_information
        Rails.cache.fetch("#{@authenticator.account}/#{@authenticator.service_id}/provider_uri",
                          expires_in: 5.minutes) do
          ::OpenIDConnect::Discovery::Provider::Config.discover!(@authenticator.provider_uri)
        end
      end

      def client
        @client ||= begin
                      issuer_uri = URI(@authenticator.provider_uri)
                      ::OpenIDConnect::Client.new(
                        identifier: @authenticator.client_id,
                        secret: @authenticator.client_secret,
                        redirect_uri: @authenticator.redirect_uri,
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

      def decode_token(id_token)
        ::OpenIDConnect::ResponseObject::IdToken.decode(
          id_token,
          discovery_information.jwks
        )
      end
    end
  end
end