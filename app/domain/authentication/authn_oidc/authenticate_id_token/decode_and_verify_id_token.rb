require 'uri'
require 'openid_connect'

module Authentication
  module AuthnOidc
    module AuthenticateIdToken
      DecodeAndVerifyIdToken = CommandClass.new(
        dependencies: {
        },
        inputs: %i(provider_uri id_token_jwt)
      ) do

        def call
          discovered_provider
          decoded_id_token
          verify_id_token

          # return decoded attributes as hash
          decoded_attributes
        end

        private

        def verify_id_token
          # Verify id_token expiration. OpenIDConnect requires to verify few claims.
          # Mask required claims such that effectively only expiration will be verified
          expected = { client_id: decoded_attributes[:aud] || decoded_attributes[:client_id],
                       issuer: decoded_attributes[:iss],
                       nonce: decoded_attributes[:nonce] }

          decoded_id_token.verify!(expected)
        rescue OpenIDConnect::ResponseObject::IdToken::ExpiredToken
          raise IdTokenExpired
        rescue => e
          raise IdTokenVerifyFailed, e.to_s
        end

        def decoded_attributes
          @decoded_attributes ||= decoded_id_token.raw_attributes
        end

        def decoded_id_token
          @decoded_id_token ||= OpenIDConnect::ResponseObject::IdToken.decode(
            @id_token_jwt,
            get_cert
          )
        rescue => e
          raise IdTokenInvalidFormat, e.to_s
        end

        def discovered_provider
          @discovered_provider ||= OpenIDConnect::Discovery::Provider::Config.discover!(@provider_uri)
        rescue HTTPClient::ConnectTimeoutError => e
          raise ProviderDiscoveryTimeout, @provider_uri
        rescue => e
          raise ProviderDiscoveryFailed, @provider_uri
        end

        def get_cert
          discovered_provider.jwks
        rescue => e
          raise ProviderRetrieveCertificateFailed, @provider_uri
        end
      end
    end
  end
end
