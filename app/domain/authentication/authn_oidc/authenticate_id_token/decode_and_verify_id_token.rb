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
          decode_id_token
          verify_id_token

          # return decoded attributes as hash
          decoded_attributes
        end

        private

        def decode_id_token
          decoded_id_token
        end

        def verify_id_token
          # Verify id_token expiration. OpenIDConnect requires to verify few claims.
          # Mask required claims such that effectively only expiration will be verified
          expected = { client_id: decoded_attributes[:aud] || decoded_attributes[:client_id],
                       issuer: decoded_attributes[:iss],
                       nonce: decoded_attributes[:nonce] }

          decoded_id_token.verify!(expected)
        end

        def decoded_attributes
          @decoded_attributes ||= decoded_id_token.raw_attributes
        end

        def decoded_id_token
          @decoded_id_token ||= OpenIDConnect::ResponseObject::IdToken.decode(
            @id_token_jwt,
            get_cert(@provider_uri)
          )
        end

        def get_cert(provider_uri)
          OpenIDConnect::Discovery::Provider::Config.discover!(provider_uri).jwks
        end
      end
    end
  end
end
