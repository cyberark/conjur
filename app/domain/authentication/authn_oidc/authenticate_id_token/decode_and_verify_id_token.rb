require 'uri'
require 'openid_connect'

module Authentication
  module AuthnOidc
    module AuthenticateIdToken
      DecodeAndVerifyIdToken = CommandClass.new(
        dependencies: {
          fetch_provider_certificate: ::Authentication::AuthnOidc::AuthenticateIdToken::FetchProviderCertificate.new,
          logger: Rails.logger
        },
        inputs: %i(provider_uri id_token_jwt)
      ) do

        def call
          # we fetch the certs & decode the id token here to propagate relevant errors
          fetch_certs
          decode_id_token
          verify_decoded_id_token
          decoded_attributes # return decoded attributes as hash
        end

        private

        def decode_id_token
          decoded_id_token
          @logger.debug("[OIDC] Decode ID Token succeeded")
        end

        def verify_decoded_id_token
          # Verify id_token expiration. OpenIDConnect requires to verify few claims.
          # Mask required claims such that effectively only expiration will be verified
          expected = { client_id: decoded_attributes[:aud] || decoded_attributes[:client_id],
                       issuer: decoded_attributes[:iss],
                       nonce: decoded_attributes[:nonce] }

          decoded_id_token.verify!(expected)
          @logger.debug("[OIDC] ID Token verification succeeded")
        rescue OpenIDConnect::ResponseObject::IdToken::ExpiredToken
          raise IdTokenExpired
        rescue => e
          raise IdTokenVerifyFailed, e.inspect
        end

        def fetch_certs
          @certs = @fetch_provider_certificate.(provider_uri: @provider_uri)
        end

        def decoded_attributes
          @decoded_attributes ||= decoded_id_token.raw_attributes
        end

        def decoded_id_token
          @decoded_id_token ||= OpenIDConnect::ResponseObject::IdToken.decode(
            @id_token_jwt,
            @certs
          )
        rescue => e
          raise IdTokenInvalidFormat, e.inspect
        end
      end
    end
  end
end
